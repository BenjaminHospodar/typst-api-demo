#!/bin/bash
# scripts/seed-all.sh
# Seeds all templates from the templates/ directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Seeding all templates..."

for form_dir in "$REPO_DIR/templates"/*/; do
    form=$(basename "$form_dir")
    for typ_file in "$form_dir"*.typ; do
        if [ -f "$typ_file" ]; then
            filename=$(basename "$typ_file" .typ)
            version="${filename#v}"
            echo "  -> $form $version"
            "$SCRIPT_DIR/seed-templates.sh" "$typ_file" "$form" "$version"
        fi
    done
done

echo "All templates seeded."
