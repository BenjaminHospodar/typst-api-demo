# k6 stress suite

Requires a running API (`docker compose up`) and [k6](https://grafana.com/docs/k6/latest/set-up/install-k6/).

Default SLOs (printed as k6 thresholds): **error rate < 5%**, **p50 < 2s**, **p95 < 5s**, **p99 < 10s** on the mixed generate mix. k6 also reports `http_req_duration` p50/p95/p99.

```bash
export BASE_URL=http://localhost:8080
export PDFGEN_API_KEY=   # if set on the API

k6 run scripts/stress/generate.js     # warmup + sustained + spike, mixed templates + async poll
k6 run scripts/stress/errors.js       # 404 / 400 / 413 / 422
./scripts/stress/run.sh generate      # or run.ps1 -Scenario generate
```

Smoke test (not k6): `python scripts/test_functional.py` — uses the OpenAPI invoice 2.0.0 example.

## Failure scenarios

Sidecar kill (circuit breaker / 503):

```bash
docker compose stop rust-compiler
k6 run scripts/stress/sidecar-kill.js
docker compose start rust-compiler
```

Rabbit saturation (async 202 / 503 under flood):

```bash
k6 run scripts/stress/rabbit-flood.js
```

Python alternatives without k6: `scripts/stress_sync.py`, `scripts/stress_errors.py`.
