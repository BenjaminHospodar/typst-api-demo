#!/bin/bash
# scripts/seed-templates.sh
# Usage: ./scripts/seed-templates.sh templates/invoice/v2.1.0.typ invoice 2.1.0
#
# Seeds a .typ template into PostgreSQL and warms the Redis cache.

set -euo pipefail

FILE="${1:?Usage: $0 <file.typ> <form> <version>}"
FORM="${2:?Usage: $0 <file.typ> <form> <version>}"
VERSION="${3:?Usage: $0 <file.typ> <form> <version>}"

DATABASE_URL="${DATABASE_URL:-postgresql://pdfgen:pdfgen@localhost:5432/pdfgen}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"

if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found"
    exit 1
fi

SOURCE=$(cat "$FILE")

echo "Seeding template: form=$FORM version=$VERSION from $FILE"

# Insert or update in PostgreSQL
psql "$DATABASE_URL" <<SQL
  INSERT INTO templates (form, version, typ_source, schema, active)
  VALUES ('$FORM', '$VERSION', \$\$${SOURCE}\$\$, '{}', true)
  ON CONFLICT (form, version) DO UPDATE SET typ_source = EXCLUDED.typ_source;
SQL

# Warm Redis cache
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET "template:${FORM}:${VERSION}" "$SOURCE"

echo "Seeded $FORM $VERSION successfully"
