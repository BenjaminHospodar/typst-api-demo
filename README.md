# Typst PDF Generation Pipeline

Learning-oriented MVP. Java is the HTTP/business API; a stateless Rust gRPC sidecar compiles Typst. **This is not a finished production stack.** The living plan is [`docs/ROADMAP.md`](docs/ROADMAP.md). Phases 0–4 are in-repo (OpenAPI, RabbitMQ, Resilience4j, API key). Kubernetes/Helm and the k6 stress suite are later.

## Quick Start

```bash
# 1. Start infrastructure (Postgres applies migrations/ on first boot)
docker-compose up -d postgres redis rabbitmq rust-compiler

# 2. Wait for services to be healthy
docker-compose ps

# 3. Seed templates from templates/ (skips _test_compile.typ CLI fixtures)
pip install -r scripts/requirements.txt
DATABASE_URL="postgresql://pdfgen:pdfgen@localhost:5432/pdfgen" \
  python scripts/seed_templates.py

# 4. Build and start all services
docker-compose up --build

# 5. Generate a PDF
curl -X POST http://localhost:8080/api/v1/generate \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: demo-invoice-1" \
  -d '{
    "form": "invoice",
    "version": "2.0.0",
    "fields": {
      "name": "Acme Corp",
      "date": "2024-04-13",
      "text1": "Consulting services — April 2024"
    }
  }' --output invoice.pdf
```

If `PDFGEN_API_KEY` is set, also send `-H "X-API-Key: $PDFGEN_API_KEY"`. Prod always requires it.

Health: `GET http://localhost:8080/actuator/health` (readiness: DB + Redis + Rabbit + gRPC compiler). Spec: [`openapi/openapi.yaml`](openapi/openapi.yaml), Swagger UI `/swagger-ui.html`. Rabbit management (local): `http://localhost:15672`.

Local CLI fixture (invoice 2.1.0):

```bash
cd templates/invoice
typst compile --input data="$(cat fixture.json)" _test_compile.typ
```

## Architecture (after Phase 4)

```
Client
  -> Java API (API key + Idempotency-Key): validate fields/schema,
     enqueue pdfgen.jobs (or in-process if Rabbit is off), wait sync-timeout-ms
  -> Java worker: gRPC Compile(job_id, template_source, inputs_json)
     with deadline, Resilience4j retry/CB/bulkhead/timeout, return PDF
  -> Rust sidecar: stateless Typst 0.12, sys.inputs.data = inputs_json, no Redis
  -> RabbitMQ: work queue + domain events (job.queued / job.compiled / job.failed) + DLQ
  -> Redis: short-lived PDF cache, job status, idempotency keys
  -> PostgreSQL: template registry + job audit (pending/compiling/done/error + compile_ms)
```

Field values are JSON, never interpolated into Typst source. Templates bind with:

```typ
#let vars = json.decode(sys.inputs.at("data", default: "{}"))
```

- **Schema source of truth:** [`migrations/V1__init.sql`](migrations/V1__init.sql) (compose initdb). Seed from `templates/` via scripts, not a second SQL dump.
- **Prod overlay:** [`docker-compose.prod.yml`](docker-compose.prod.yml) (no published DB/Rabbit ports; secrets from env).

## HTTP headers

| Header | When | Purpose |
| ------ | ---- | ------- |
| `X-API-Key` | Required when `PDFGEN_API_KEY` is set (always in `prod`) | Rejects unauthenticated `/api/**`. Health, OpenAPI, and Swagger stay public; prod disables Swagger. |
| `Idempotency-Key` | Optional on `POST /api/v1/generate` | Redis SET NX for 24h. Replay returns the same job’s PDF, `202` poll, or the original error. |
| `Retry-After: 5` | `503` | Sidecar/queue/circuit-breaker unavailable. |

## Rabbit topology

| Name | Kind | Purpose |
| ---- | ---- | ------- |
| `pdfgen.jobs` | direct exchange | Work queue. Routing key `generate`. |
| `pdfgen.jobs.q` | durable queue | Java `@RabbitListener` workers call gRPC. DLX `pdfgen.jobs.dlx`. |
| `pdfgen.jobs.dlx` / `pdfgen.jobs.dlq` | DLX + queue | Poison messages after listener retries (`default-requeue-rejected: false`). Compile errors are acked, not retried. |
| `pdfgen.events` | topic exchange | Domain events, routing key = `job.queued` / `job.compiled` / `job.failed`. |
| `pdfgen.events.q` | durable queue | Bound `job.*`, TTL 1h, max 10k (inspect in management UI; not an application log dump). |

Stdout is JSON (Logstash encoder + Rust `RUST_LOG_FORMAT=json`). Do not treat Rabbit events as a log pipeline.

Default `pdfgen.rabbit.enabled: false` (in-process worker, no broker). Profiles `local` and `prod` turn Rabbit on.

## What compiles in-service

The embedded Typst World still has no package resolver. Server templates do **not** import `@preview/...` (stripped in Phase 1). Local `typst compile` can still fetch Universe packages if you add those imports yourself; the sidecar will not.

| Template | In-service | Notes |
|----------|------------|--------|
| `minimal` 1.0.0 | yes | |
| `invoice` 2.0.0 | yes | Honest demo / smoke-test target |
| `invoice` 2.1.0 | yes | QR replaced with a placeholder; needs `image.png` via `TYPST_ASSETS_DIR` |
| `report` 1.0.0 / 2.0.0 | yes | |
| `contract` 1.0.0 | yes | |
| `dashboard` 1.0.0 | yes | |
| `legal` 1.0.0 | likely | No packages; font may fall back |
| `rrsp` 1.0.0 | yes | cetz/tiaoma replaced with native Typst |
| `*/_test_compile.typ` | not seeded | Local CLI fixtures: `typst compile --input data=...` |

## API Endpoints

| Method | Path                       | Description |
| ------ | -------------------------- | ----------- |
| POST   | `/api/v1/generate`         | Enqueue compile; wait `pdfgen.queue.sync-timeout-ms` then return PDF or `202` + `job_id` |
| GET    | `/api/v1/jobs/{id}/result` | Poll for async PDF |
| GET    | `/actuator/health`         | Spring Actuator (DB, Redis, Rabbit when enabled, compiler sidecar) |
| GET    | `/actuator/health/readiness` | Probe group: db + redis + compiler (+ rabbit on local/prod) |
| GET    | `/swagger-ui.html`         | Swagger UI (disabled in prod) |
| GET    | `/v3/api-docs`             | springdoc JSON |
| GET    | `/openapi.yaml`            | Checked-in spec |

gRPC contract (`typst.compile.v1`):

- `Compile(job_id, template_source, inputs_json) -> { pdf_bytes, pages, compile_ms, error }`
- `Health() -> { ok, typst_version }`

Limits (`pdfgen.limits`): template 1 MiB, 200 fields, PDF 20 MiB. gRPC deadline `pdfgen.compiler.deadline-ms` (30s) and max message size 20 MiB.

## Project Structure

```
repo/
├── docs/ROADMAP.md         # Living productionization plan
├── openapi/openapi.yaml    # Spec-first OpenAPI
├── java-api/               # Spring Boot API (Gradle wrapper: gradlew, gradle-wrapper.jar)
├── rust-compiler/          # Stateless gRPC Typst sidecar
├── templates/              # Source .typ (seed these; skip _test_compile.typ)
├── migrations/             # PostgreSQL schema (source of truth)
├── scripts/                # Python: seed, smoke, stress (see scripts/README.md)
├── docker-compose.yml
└── docker-compose.prod.yml
```
