#!/bin/bash
set -euo pipefail

echo "=== PDF Gen Seeder ==="

# ── Wait for PostgreSQL ──────────────────────────────────────
echo "Waiting for PostgreSQL..."
until pg_isready -h "$POSTGRES_HOST" -U pdfgen; do sleep 1; done
echo "PostgreSQL ready."

# ── Run migrations ───────────────────────────────────────────
echo "Running migrations..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U pdfgen -d pdfgen <<'SQL'
CREATE TABLE IF NOT EXISTS templates (
    id         BIGSERIAL PRIMARY KEY,
    form       VARCHAR(64)  NOT NULL,
    version    VARCHAR(32)  NOT NULL,
    typ_source TEXT         NOT NULL,
    schema     JSONB        NOT NULL DEFAULT '{}',
    active     BOOLEAN      NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (form, version)
);
CREATE TABLE IF NOT EXISTS jobs (
    id           VARCHAR(26)  PRIMARY KEY,
    form         VARCHAR(64)  NOT NULL,
    version      VARCHAR(32)  NOT NULL,
    status       VARCHAR(16)  NOT NULL DEFAULT 'queued',
    queued_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    started_at   TIMESTAMPTZ,
    finished_at  TIMESTAMPTZ,
    error_msg    TEXT,
    page_count   INTEGER,
    compile_ms   INTEGER
);
SQL
echo "Migrations done."

# ── Wait for Redis ───────────────────────────────────────────
echo "Waiting for Redis..."
until redis-cli -h "$REDIS_HOST" ping | grep -q PONG; do sleep 1; done
echo "Redis ready."

# ── Seed all templates ───────────────────────────────────────
echo "Seeding templates..."
SEEDED=0

for typ_file in /templates/*/*.typ; do
    [ ! -f "$typ_file" ] && continue
    form=$(basename "$(dirname "$typ_file")")
    version=$(basename "$typ_file" .typ | sed 's/^v//')

    echo "  -> $form v$version"

    # Redis
    cat "$typ_file" | redis-cli -h "$REDIS_HOST" -x SET "template:${form}:${version}" > /dev/null

    # PostgreSQL
    sql_source=$(cat "$typ_file" | sed "s/'/''/g")
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U pdfgen -d pdfgen -c \
        "INSERT INTO templates (form, version, typ_source, schema, active)
         VALUES ('${form}', '${version}', E'${sql_source}', '{}', true)
         ON CONFLICT (form, version) DO UPDATE SET typ_source = EXCLUDED.typ_source;" \
        > /dev/null 2>&1

    SEEDED=$((SEEDED + 1))
done

echo ""
echo "=== Seeder complete: $SEEDED templates seeded ==="
