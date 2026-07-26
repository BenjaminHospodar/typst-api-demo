FROM rust:slim-bookworm AS build
WORKDIR /app

# Install protobuf compiler
RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Cache dependencies
COPY Cargo.toml ./
RUN mkdir src && echo "fn main(){}" > src/main.rs && mkdir proto
COPY proto ./proto
COPY build.rs ./
RUN cargo build --release 2>/dev/null || true
RUN rm -rf src

# Build service
COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/target/release/typst-compiler-svc .

# Copy template assets (logo images, etc.)
RUN mkdir -p /assets
COPY assets/ /assets/

EXPOSE 50051
ENV WORKER_THREADS=4
ENV RUST_LOG=info
ENV TYPST_ASSETS_DIR=/assets
ENTRYPOINT ["./typst-compiler-svc"]
