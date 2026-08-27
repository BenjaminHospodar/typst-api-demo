#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export BASE_URL="${BASE_URL:-http://localhost:8080}"
SCENARIO="${1:-generate}"

case "$SCENARIO" in
  sidecar-kill)
    docker compose stop rust-compiler
    trap 'docker compose start rust-compiler' EXIT
    k6 run "$HERE/sidecar-kill.js"
    ;;
  generate|errors|rabbit-flood)
    k6 run "$HERE/${SCENARIO}.js"
    ;;
  *)
    echo "usage: $0 generate|errors|sidecar-kill|rabbit-flood" >&2
    exit 1
    ;;
esac
