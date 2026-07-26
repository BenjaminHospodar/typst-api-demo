#!/bin/bash
# ============================================================
#  PDF Generation Pipeline — One-Command Setup
#  Run on TrueNAS / any Docker host:
#    chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  PDF Generation Pipeline — Setup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

# ── Step 1: Load images ─────────────────────────────────────
if [ -f "pdfgen-images.tar" ]; then
    echo -e "${YELLOW}[1/4] Loading Docker images...${NC}"
    docker load -i pdfgen-images.tar
    echo -e "${GREEN}  ✓ Images loaded${NC}"
else
    echo -e "${YELLOW}[1/4] No pdfgen-images.tar found, checking if images exist...${NC}"
    if docker image inspect pdfgen-java-api:latest >/dev/null 2>&1 && \
       docker image inspect pdfgen-rust-compiler:latest >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Images already present${NC}"
    else
        echo "ERROR: pdfgen-images.tar not found and images not loaded."
        echo "Copy pdfgen-images.tar to this directory and re-run."
        exit 1
    fi
fi
echo ""

# ── Step 2: Start stack ─────────────────────────────────────
echo -e "${YELLOW}[2/4] Starting services...${NC}"
docker compose -f docker-compose.portainer.yml up -d
echo -e "${GREEN}  ✓ Stack started${NC}"
echo ""

# ── Step 3: Wait for healthy services ────────────────────────
echo -e "${YELLOW}[3/4] Waiting for services to become healthy...${NC}"

POSTGRES=""
REDIS=""

for i in $(seq 1 30); do
    if [ -z "$POSTGRES" ]; then
        POSTGRES=$(docker ps --filter "label=com.docker.compose.service=postgres" --format "{{.Names}}" | head -1)
    fi
    if [ -z "$REDIS" ]; then
        REDIS=$(docker ps --filter "label=com.docker.compose.service=redis" --format "{{.Names}}" | head -1)
    fi
    if [ -n "$POSTGRES" ] && [ -n "$REDIS" ]; then
        break
    fi
    sleep 1
done

if [ -z "$POSTGRES" ] || [ -z "$REDIS" ]; then
    echo "ERROR: Could not find postgres/redis containers. Check 'docker ps'."
    exit 1
fi

# Wait for postgres healthy
for i in $(seq 1 30); do
    if docker exec "$POSTGRES" pg_isready -U pdfgen >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ PostgreSQL ready${NC}"
        break
    fi
    if [ "$i" -eq 30 ]; then echo "ERROR: PostgreSQL not ready after 30s"; exit 1; fi
    sleep 1
done

# Wait for redis healthy
for i in $(seq 1 30); do
    if docker exec "$REDIS" redis-cli ping >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Redis ready${NC}"
        break
    fi
    if [ "$i" -eq 30 ]; then echo "ERROR: Redis not ready after 30s"; exit 1; fi
    sleep 1
done

# Wait for java-api
for i in $(seq 1 60); do
    if curl -sf http://localhost:8080/api/v1/health >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Java API ready${NC}"
        break
    fi
    if [ "$i" -eq 60 ]; then echo "ERROR: Java API not ready after 60s"; exit 1; fi
    sleep 1
done
echo ""

# ── Step 4: Seed templates ──────────────────────────────────
echo -e "${YELLOW}[4/4] Seeding templates...${NC}"
SEEDED=0

for form_dir in templates/*/; do
    [ ! -d "$form_dir" ] && continue
    form=$(basename "$form_dir")
    for typ_file in "$form_dir"*.typ; do
        [ ! -f "$typ_file" ] && continue
        filename=$(basename "$typ_file" .typ)
        version="${filename#v}"

        # Seed to Redis
        cat "$typ_file" | docker exec -i "$REDIS" redis-cli -x SET "template:${form}:${version}" >/dev/null

        # Seed to PostgreSQL
        sql_source=$(cat "$typ_file" | sed "s/'/''/g")
        docker exec -i "$POSTGRES" psql -U pdfgen -d pdfgen -c \
            "INSERT INTO templates (form, version, typ_source, schema, active)
             VALUES ('${form}', '${version}', E'${sql_source}', '{}', true)
             ON CONFLICT (form, version) DO UPDATE SET typ_source = EXCLUDED.typ_source;" \
            >/dev/null 2>&1

        echo -e "  ${GREEN}✓${NC} ${form} v${version}"
        SEEDED=$((SEEDED + 1))
    done
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete! ${SEEDED} templates seeded.${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""
echo "  API endpoint:  http://$(hostname -f 2>/dev/null || echo localhost):8080/api/v1/generate"
echo ""
echo "  Test it:"
echo '  curl -X POST http://localhost:8080/api/v1/generate \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"form":"minimal","version":"1.0.0","fields":{"name":"Test","date":"2026-04-13"}}'"'"' \'
echo '    --output test.pdf'
echo ""
