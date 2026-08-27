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

Match LXC memory to compose `deploy.resources.limits` in `docker-compose.prod.yml`. Start with 2 rust-compiler replicas; scale after stress tests (`k6 run scripts/stress/generate.js`).

## Next steps

```bash
# k3s in the same LXC (needs metrics-server for HPA)
kubectl apply -k k8s/overlays/local
kubectl -n pdfgen port-forward svc/java-api 8080:8080
```

Keep Compose until that overlay is boring. Do not introduce AWS/Azure-specific brokers until then.
