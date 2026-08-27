# Proxmox LXC deployment notes

Deploy with Docker Compose inside an LXC before moving to Kubernetes.

## LXC prerequisites

1. Create an LXC with nesting enabled (or privileged container) so Docker Engine runs inside.
2. Enable `keyctl` if using Docker-in-LXC (Proxmox: Features → nesting + keyctl).
3. Allocate enough memory for postgres + rabbitmq + redis + java-api + rust-compiler (recommend 4GB+).

## Deploy steps

```bash
# On the LXC host
git clone <repo> && cd typst-api-demo

# Set production secrets
cp .env.example .env
# edit POSTGRES_PASSWORD, REDIS_PASSWORD, RABBITMQ_PASSWORD, PDFGEN_API_KEY

docker compose -f docker-compose.prod.yml up --build -d

# Seed templates (from host or inside LXC)
pip install -r scripts/requirements.txt
python scripts/seed_templates.py
```

## Validation

```bash
curl "http://localhost:${JAVA_API_PORT:-8080}/actuator/health/readiness"
python scripts/test_functional.py
```

## Resource limits

Match LXC memory to compose `deploy.resources.limits` in `docker-compose.prod.yml`. Start with 2 rust-compiler replicas; scale after stress tests (`scripts/stress_sync.py`, `scripts/stress_errors.py`).

## Next steps

- Run k3s in the same LXC using manifests in `k8s/overlays/local/`
- Or keep Compose until Helm chart is boring (see `k8s/`)
