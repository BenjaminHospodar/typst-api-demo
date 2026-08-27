# Scripts

All operational scripts load the repo-root `.env` automatically (`DATABASE_URL`, `REDIS_URL`, `BASE_URL`, `PDFGEN_API_KEY`). Python deps once:

```bash
cp .env.example .env   # if you have not already
pip install -r scripts/requirements.txt
```

## Seeding

```bash
python scripts/seed_templates.py
```

Options: `--dry-run`, `--no-wait`, `--templates-dir`, `--database-url`

## Smoke tests

```bash
python scripts/test_functional.py
python scripts/test_functional.py "$BASE_URL"
```

## Stress tests

Preferred: [k6](https://grafana.com/docs/k6/latest/set-up/install-k6/) against a live stack (`docker compose up`). See [`stress/README.md`](stress/README.md).

```bash
k6 run scripts/stress/generate.js
k6 run scripts/stress/errors.js
./scripts/stress/run.sh sidecar-kill
./scripts/stress/run.ps1 -Scenario sidecar-kill
```

k6 reports p50/p95/p99 on `http_req_duration`. Default generate SLOs: error rate < 5%, p95 < 5s, p99 < 10s.

Python fallback (no k6):

```bash
python scripts/stress_sync.py
python scripts/stress_sync.py --quick
python scripts/stress_errors.py
python scripts/stress_sync.py --api-key "$PDFGEN_API_KEY"
```
