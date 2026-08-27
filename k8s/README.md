# Kubernetes

Kustomize overlays for k3s after Compose is proven on the LXC. Not a cloud-vendor chart.

```bash
kubectl apply -k k8s/overlays/local
kubectl -n pdfgen port-forward svc/java-api 8080:8080
```

Prod: `kubectl apply -k k8s/overlays/prod` after replacing placeholder secrets in `overlays/prod/secrets.yaml`.

## Included

- Deployments: postgres (init from `migrations/V1__init.sql`), redis, rabbitmq, java-api, rust-compiler
- HPA on rust-compiler (CPU; needs metrics-server)
- Probes: Actuator on Java, `grpc.health.v1` on Rust
- NetworkPolicy: only pods labeled `app=java-api` may reach `rust-compiler:50051`

Build images as `typst-api-demo/java-api:latest` and `typst-api-demo/rust-compiler:latest` (or change the image fields). Do not point these manifests at RDS/MSK/Event Hubs until this overlay is boring on k3s.

See [`docs/PROXMOX_LXC.md`](../docs/PROXMOX_LXC.md) for Compose-first LXC steps.
