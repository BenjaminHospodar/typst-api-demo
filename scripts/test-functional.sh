#!/bin/bash
# scripts/test-functional.sh
# Functional tests for the PDF generation pipeline.
# Usage: ./scripts/test-functional.sh [base_url]

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
PASS=0
FAIL=0
ERRORS=""

green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }
bold()  { echo -e "\033[1m$1\033[0m"; }

assert_status() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$actual" = "$expected" ]; then
        green "  PASS: $test_name (HTTP $actual)"
        PASS=$((PASS + 1))
    else
        red "  FAIL: $test_name (expected $expected, got $actual)"
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  - $test_name"
    fi
}

bold "=== PDF Generation Pipeline — Functional Tests ==="
echo ""

# ── Test 1: Health check ─────────────────────────────────────
bold "1. Health check"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/v1/health")
assert_status "GET /api/v1/health" "200" "$STATUS"

# ── Test 2: Generate invoice (sync) ──────────────────────────
bold "2. Generate invoice v2.1.0 (sync)"
TMPFILE=$(mktemp /tmp/test-pdf-XXXXXX.pdf)
STATUS=$(curl -s -o "$TMPFILE" -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "invoice",
        "version": "2.1.0",
        "fields": {
            "name": "Acme Corp",
            "date": "2024-04-13",
            "text1": "Consulting services",
            "text3": "Net 30",
            "text4": "Wire transfer preferred"
        }
    }')
if [ "$STATUS" = "200" ]; then
    # Verify it's actually a PDF (starts with %PDF)
    MAGIC=$(head -c 4 "$TMPFILE")
    if [ "$MAGIC" = "%PDF" ]; then
        SIZE=$(stat -f%z "$TMPFILE" 2>/dev/null || stat --printf="%s" "$TMPFILE" 2>/dev/null || echo "?")
        green "  PASS: Invoice PDF generated ($SIZE bytes)"
        PASS=$((PASS + 1))
    else
        red "  FAIL: Response is not a valid PDF"
        FAIL=$((FAIL + 1))
        ERRORS="$ERRORS\n  - Invoice PDF validation"
    fi
elif [ "$STATUS" = "202" ]; then
    green "  PASS: Invoice returned async (202) — system under load"
    PASS=$((PASS + 1))
else
    assert_status "Generate invoice" "200" "$STATUS"
fi
rm -f "$TMPFILE"

# ── Test 3: Generate invoice v2.0.0 ─────────────────────────
bold "3. Generate invoice v2.0.0"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "invoice",
        "version": "2.0.0",
        "fields": {"name": "Test Corp", "date": "2024-01-01", "text1": "Hello"}
    }')
if [ "$STATUS" = "200" ] || [ "$STATUS" = "202" ]; then
    green "  PASS: Invoice v2.0.0 (HTTP $STATUS)"
    PASS=$((PASS + 1))
else
    assert_status "Generate invoice v2.0.0" "200|202" "$STATUS"
fi

# ── Test 4: Generate report (complex tables) ─────────────────
bold "4. Generate report v2.0.0 (tables + columns)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "report",
        "version": "2.0.0",
        "fields": {
            "name": "GlobalTech Inc",
            "date": "2024-12-31",
            "text1": "Outstanding year with record revenue.",
            "text3": "Projected growth of 25% next fiscal year."
        }
    }')
if [ "$STATUS" = "200" ] || [ "$STATUS" = "202" ]; then
    green "  PASS: Report v2.0.0 (HTTP $STATUS)"
    PASS=$((PASS + 1))
else
    assert_status "Generate report v2.0.0" "200|202" "$STATUS"
fi

# ── Test 5: Generate contract (multi-page) ───────────────────
bold "5. Generate contract v1.0.0 (multi-page)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "contract",
        "version": "1.0.0",
        "fields": {
            "name": "MegaCorp LLC",
            "date": "2024-06-15",
            "text1": "Full-stack development services for Project Phoenix."
        }
    }')
if [ "$STATUS" = "200" ] || [ "$STATUS" = "202" ]; then
    green "  PASS: Contract v1.0.0 (HTTP $STATUS)"
    PASS=$((PASS + 1))
else
    assert_status "Generate contract v1.0.0" "200|202" "$STATUS"
fi

# ── Test 6: Generate dashboard (complex layout) ──────────────
bold "6. Generate dashboard v1.0.0 (KPI cards + tables)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "dashboard",
        "version": "1.0.0",
        "fields": {
            "name": "SaaS Metrics Co",
            "date": "2024-04-13",
            "text1": "Record month for user signups.",
            "text3": "Next board meeting in 2 weeks."
        }
    }')
if [ "$STATUS" = "200" ] || [ "$STATUS" = "202" ]; then
    green "  PASS: Dashboard v1.0.0 (HTTP $STATUS)"
    PASS=$((PASS + 1))
else
    assert_status "Generate dashboard v1.0.0" "200|202" "$STATUS"
fi

# ── Test 7: Missing template (should 404) ────────────────────
bold "7. Missing template (expect 404)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{"form": "nonexistent", "version": "1.0.0", "fields": {"name": "X"}}')
assert_status "Missing template returns 404" "404" "$STATUS"

# ── Test 8: Invalid request (missing fields) ─────────────────
bold "8. Invalid request (missing required fields)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{"form": "", "version": ""}')
assert_status "Invalid request returns 400" "400" "$STATUS"

# ── Test 9: Minimal template (fast path) ─────────────────────
bold "9. Minimal template (fast path)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "form": "minimal",
        "version": "1.0.0",
        "fields": {"name": "Speed Test", "date": "2024-04-13"}
    }')
if [ "$STATUS" = "200" ] || [ "$STATUS" = "202" ]; then
    green "  PASS: Minimal template (HTTP $STATUS)"
    PASS=$((PASS + 1))
else
    assert_status "Generate minimal" "200|202" "$STATUS"
fi

# ── Test 10: Poll endpoint (with fake job_id = 404) ──────────
bold "10. Poll with invalid job_id (expect 404)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/v1/jobs/FAKEID/result")
assert_status "Invalid job poll returns 404" "404" "$STATUS"

# ── Summary ──────────────────────────────────────────────────
echo ""
bold "=== Results ==="
green "Passed: $PASS"
if [ "$FAIL" -gt 0 ]; then
    red "Failed: $FAIL"
    red "Failures:$ERRORS"
    exit 1
else
    green "All tests passed!"
fi
