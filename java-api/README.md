# Java API

Spring Boot 3.2 / Java 21 HTTP façade. Owns templates, jobs, Redis cache, RabbitMQ, and the gRPC client to the Rust sidecar.

## Run

```bash
# from repo root, with Postgres/Redis/Rabbit (and the sidecar) up
docker compose up --build java-api
```

Local JVM (JDK 21):

```bash
cd java-api
./gradlew bootRun
```

Uses [`application-local.yml`](src/main/resources/application-local.yml) when `SPRING_PROFILES_ACTIVE=local`. Tests force `pdfgen.rabbit.enabled=false` (in-process worker).

```bash
./gradlew test
```

## What it does

1. `POST /api/v1/generate` — validate fields + JSON Schema `required`, claim optional `Idempotency-Key`, insert job row, publish `pdfgen.jobs`.
2. Worker (`JobWorker` or `LocalJobPublisher`) loads Typst from Postgres (Caffeine), calls `Compile` with a deadline, stores PDF in Redis (5 min TTL), updates Postgres `jobs`.
3. Sync wait polls Redis status for `pdfgen.queue.sync-timeout-ms` then returns the PDF or `202` + poll URL.

## Auth and limits

- `X-API-Key` required when `PDFGEN_API_KEY` is set (always in `prod`).
- Payload caps in `pdfgen.limits` (template size, field count, PDF size).
- Resilience4j on the gRPC stub: retry (unavailable only), circuit breaker, bulkhead, time limiter.

## Spec

Checked-in OpenAPI: [`../openapi/openapi.yaml`](../openapi/openapi.yaml). Swagger UI `/swagger-ui.html` (disabled in prod). Proto is generated from [`../rust-compiler/proto/compile.proto`](../rust-compiler/proto/compile.proto).
