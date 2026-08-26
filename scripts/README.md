# Scripts

All operational scripts are Python. They load the repo-root `.env` automatically (`DATABASE_URL`, `REDIS_URL`, `BASE_URL`). Install dependencies once:

```bash
cp .env.example .env   # if you have not already
pip install -r scripts/requirements.txt
```

## Seeding

```bash
python scripts/seed_templates.py
```

Options: `--no-redis`, `--dry-run`, `--no-wait`, `--templates-dir`, `--database-url`, `--redis-url`

## Smoke tests

```bash
python scripts/test_functional.py
python scripts/test_functional.py "$BASE_URL"
```

## Stress tests

Run against a live stack (`docker compose up`).

```bash
python scripts/stress_sync.py
python scripts/stress_sync.py --quick
python scripts/stress_errors.py
python scripts/stress_sync.py --api-key "$PDFGEN_API_KEY"
```

Default SLOs (sync suite): error rate &lt; 5%, p95 latency &lt; 5s.
