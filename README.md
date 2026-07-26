# Typst PDF Generation Pipeline

## Quick Start

```bash
# 1. Start infrastructure
docker-compose up -d postgres redis

# 2. Wait for services to be healthy
docker-compose ps

# 3. Seed templates
DATABASE_URL="postgresql://pdfgen:pdfgen@localhost:5432/pdfgen" \
  ./scripts/seed-all.sh

# 4. Build and start all services
docker-compose up --build

# 5. Generate a PDF
curl -X POST http://localhost:8080/api/v1/generate \
  -H "Content-Type: application/json" \
  -d '{
    "form": "invoice",
    "version": "2.1.0",
    "fields": {
      "name": "Acme Corp",
      "date": "2024-04-13",
      "text1": "Consulting services — April 2024",
      "text3": "Net 30",
      "text4": "Wire transfer preferred"
    }
  }' --output invoice.pdf

# 6. Scale Rust compiler replicas
docker-compose up --scale rust-compiler=4
```

## Architecture

- **Java API** (Spring Boot) — validates requests, enqueues jobs via Redis Stream
- **Rust Compiler** (Tonic gRPC + embedded Typst) — consumes jobs, compiles PDFs
- **Redis** — job queue (Streams), template cache, result store
- **PostgreSQL** — template registry, job audit log

## API Endpoints

| Method | Path                       | Description                    |
| ------ | -------------------------- | ------------------------------ |
| POST   | `/api/v1/generate`         | Generate a PDF (sync or async) |
| GET    | `/api/v1/jobs/{id}/result` | Poll for async result          |
| GET    | `/api/v1/health`           | Health check                   |

## Project Structure

```
repo/
├── java-api/          # Spring Boot API service
├── rust-compiler/     # Rust/Typst compiler service
├── templates/         # Source .typ template files
├── migrations/        # PostgreSQL schema
├── scripts/           # Seeding and utility scripts
├── docker-compose.yml # Development compose
└── docker-compose.prod.yml # Production compose
```
