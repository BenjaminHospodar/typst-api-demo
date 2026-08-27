# Rust compile sidecar

Stateless gRPC service. Embedded Typst 0.12. No Redis, no template store, no job queue.

## Contract (`typst.compile.v1`)

Defined in [`proto/compile.proto`](proto/compile.proto) (also used by the Java client).

- `Compile(job_id, template_source, inputs_json) → { pdf_bytes, pages, compile_ms, error }`
- `Health() → { ok, typst_version }` plus standard `grpc.health.v1`

`sys.inputs.data` is the raw `inputs_json` string. Templates decode it; this process never concatenates Typst source from field values.

```typ
#let vars = json.decode(sys.inputs.at("data", default: "{}"))
```

## Run

```bash
cd rust-compiler
cargo run
```

Env: `GRPC_ADDR` (default `0.0.0.0:50051`), `GRPC_MAX_MESSAGE_SIZE` (20 MiB), `TYPST_ASSETS_DIR` (for `image("image.png")`), `RUST_LOG`, `RUST_LOG_FORMAT=json`.

```bash
grpcurl -plaintext localhost:50051 typst.compile.v1.CompileService/Health
```

Scale with replicas, not worker threads. Universe `#import "@preview/..."` is not supported.
