#!/bin/bash
# scripts/test-load.sh
# Load test: measures TPS for the PDF generation pipeline.
# Uses only curl + bash (no external tools needed).
#
# Usage: ./scripts/test-load.sh [concurrency] [total_requests] [base_url]

set -euo pipefail

CONCURRENCY="${1:-20}"
TOTAL="${2:-500}"
BASE_URL="${3:-http://localhost:8080}"
ENDPOINT="$BASE_URL/api/v1/generate"

bold()  { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }

bold "=== PDF Generation — Load Test ==="
echo "Concurrency: $CONCURRENCY"
echo "Total requests: $TOTAL"
echo "Target: $ENDPOINT"
echo ""

TMPDIR=$(mktemp -d /tmp/loadtest-XXXXXX)

# Templates to rotate through
TEMPLATES=(
    '{"form":"minimal","version":"1.0.0","fields":{"name":"LoadTest","date":"2024-04-13","text1":"Benchmark"}}'
    '{"form":"invoice","version":"2.1.0","fields":{"name":"Acme","date":"2024-04-13","text1":"Services","text3":"Net 30","text4":"Wire"}}'
    '{"form":"invoice","version":"2.0.0","fields":{"name":"Test","date":"2024-01-01","text1":"Hello"}}'
    '{"form":"report","version":"2.0.0","fields":{"name":"Corp","date":"2024-12-31","text1":"Summary","text3":"Outlook"}}'
    '{"form":"contract","version":"1.0.0","fields":{"name":"MegaCorp","date":"2024-06-15","text1":"Dev services"}}'
    '{"form":"dashboard","version":"1.0.0","fields":{"name":"Metrics","date":"2024-04-13","text1":"Record month","text3":"Next review"}}'
)
NUM_TEMPLATES=${#TEMPLATES[@]}

# Worker function
worker() {
    local worker_id=$1
    local count=$2
    local outfile="$TMPDIR/worker-$worker_id.log"
    :> "$outfile"

    for i in $(seq 1 $count); do
        local tpl_idx=$(( (worker_id * count + i) % NUM_TEMPLATES ))
        local body="${TEMPLATES[$tpl_idx]}"

        local start_ns=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
        local status=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "$ENDPOINT" \
            -H "Content-Type: application/json" \
            -d "$body" \
            --max-time 10)
        local end_ns=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")

        local latency_ms=$(( (end_ns - start_ns) / 1000000 ))
        echo "$status $latency_ms" >> "$outfile"
    done
}

# Distribute requests across workers
PER_WORKER=$((TOTAL / CONCURRENCY))
REMAINDER=$((TOTAL % CONCURRENCY))

bold "Starting $CONCURRENCY workers..."
START_TIME=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")

PIDS=()
for w in $(seq 0 $((CONCURRENCY - 1))); do
    count=$PER_WORKER
    if [ "$w" -lt "$REMAINDER" ]; then
        count=$((count + 1))
    fi
    worker "$w" "$count" &
    PIDS+=($!)
done

# Wait for all workers
for pid in "${PIDS[@]}"; do
    wait "$pid" || true
done

END_TIME=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
TOTAL_MS=$(( (END_TIME - START_TIME) / 1000000 ))
TOTAL_SEC_X100=$(( TOTAL_MS * 100 / 1000 ))

# Aggregate results
SUCCESS=0
ERRORS=0
ASYNC=0
LATENCIES=""

for f in "$TMPDIR"/worker-*.log; do
    while read -r status latency; do
        if [ "$status" = "200" ]; then
            SUCCESS=$((SUCCESS + 1))
        elif [ "$status" = "202" ]; then
            ASYNC=$((ASYNC + 1))
            SUCCESS=$((SUCCESS + 1))
        else
            ERRORS=$((ERRORS + 1))
        fi
        LATENCIES="$LATENCIES $latency"
    done < "$f"
done

# Calculate stats
if [ "$TOTAL_MS" -gt 0 ]; then
    TPS=$(( TOTAL * 1000 / TOTAL_MS ))
else
    TPS=0
fi

# Sort latencies for percentiles
SORTED=$(echo "$LATENCIES" | tr ' ' '\n' | sort -n | grep -v '^$')
COUNT=$(echo "$SORTED" | wc -l)
P50_IDX=$(( COUNT * 50 / 100 ))
P95_IDX=$(( COUNT * 95 / 100 ))
P99_IDX=$(( COUNT * 99 / 100 ))
[ "$P50_IDX" -lt 1 ] && P50_IDX=1
[ "$P95_IDX" -lt 1 ] && P95_IDX=1
[ "$P99_IDX" -lt 1 ] && P99_IDX=1

P50=$(echo "$SORTED" | sed -n "${P50_IDX}p")
P95=$(echo "$SORTED" | sed -n "${P95_IDX}p")
P99=$(echo "$SORTED" | sed -n "${P99_IDX}p")
MIN_LAT=$(echo "$SORTED" | head -1)
MAX_LAT=$(echo "$SORTED" | tail -1)

echo ""
bold "=== Results ==="
echo "Total requests:  $TOTAL"
echo "Duration:        ${TOTAL_MS} ms"
echo ""
bold "Throughput:      $TPS req/s"
echo ""
echo "Success (200):   $((SUCCESS - ASYNC))"
echo "Async (202):     $ASYNC"
echo "Errors:          $ERRORS"
echo ""
bold "Latency:"
echo "  Min:    ${MIN_LAT} ms"
echo "  P50:    ${P50} ms"
echo "  P95:    ${P95} ms"
echo "  P99:    ${P99} ms"
echo "  Max:    ${MAX_LAT} ms"

echo ""
if [ "$TPS" -ge 100 ]; then
    green "PASS: $TPS TPS >= 100 TPS target"
else
    red "FAIL: $TPS TPS < 100 TPS target"
fi

if [ "$ERRORS" -gt 0 ]; then
    red "WARNING: $ERRORS errors during test"
fi

# Cleanup
rm -rf "$TMPDIR"
