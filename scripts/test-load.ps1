# scripts/test-load.ps1
# Load test: measures TPS for the PDF generation pipeline (PowerShell version)
# Usage: .\scripts\test-load.ps1 [-Concurrency 20] [-Total 500] [-BaseUrl http://localhost:8080]

param(
    [int]$Concurrency = 20,
    [int]$Total = 500,
    [string]$BaseUrl = "http://localhost:8080"
)

$endpoint = "$BaseUrl/api/v1/generate"

$templates = @(
    '{"form":"minimal","version":"1.0.0","fields":{"name":"LoadTest","date":"2024-04-13","text1":"Benchmark"}}',
    '{"form":"invoice","version":"2.1.0","fields":{"name":"Acme","date":"2024-04-13","text1":"Services","text3":"Net 30","text4":"Wire"}}',
    '{"form":"invoice","version":"2.0.0","fields":{"name":"Test","date":"2024-01-01","text1":"Hello"}}',
    '{"form":"report","version":"2.0.0","fields":{"name":"Corp","date":"2024-12-31","text1":"Summary","text3":"Outlook"}}',
    '{"form":"contract","version":"1.0.0","fields":{"name":"MegaCorp","date":"2024-06-15","text1":"Dev services"}}',
    '{"form":"dashboard","version":"1.0.0","fields":{"name":"Metrics","date":"2024-04-13","text1":"Record month","text3":"Next review"}}'
)

Write-Host "=== PDF Generation - Load Test ===" -ForegroundColor Cyan
Write-Host "Concurrency: $Concurrency"
Write-Host "Total requests: $Total"
Write-Host "Target: $endpoint"
Write-Host ""

$perWorker = [math]::Floor($Total / $Concurrency)
$remainder = $Total % $Concurrency

$scriptBlock = {
    param($workerId, $count, $endpoint, $templates)

    $results = @()
    for ($i = 0; $i -lt $count; $i++) {
        $tplIdx = ($workerId * $count + $i) % $templates.Count
        $body = $templates[$tplIdx]

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $resp = Invoke-WebRequest -Uri $endpoint -Method POST -Body $body `
                -ContentType "application/json" -UseBasicParsing -ErrorAction Stop `
                -TimeoutSec 10
            $sw.Stop()
            $results += [PSCustomObject]@{
                Status = $resp.StatusCode
                LatencyMs = $sw.ElapsedMilliseconds
            }
        } catch {
            $sw.Stop()
            $status = 0
            if ($_.Exception.Response) {
                $status = [int]$_.Exception.Response.StatusCode
            }
            $results += [PSCustomObject]@{
                Status = $status
                LatencyMs = $sw.ElapsedMilliseconds
            }
        }
    }
    return $results
}

Write-Host "Starting $Concurrency workers..." -ForegroundColor Yellow
$overallSw = [System.Diagnostics.Stopwatch]::StartNew()

$jobs = @()
for ($w = 0; $w -lt $Concurrency; $w++) {
    $count = $perWorker
    if ($w -lt $remainder) { $count++ }

    $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $w, $count, $endpoint, $templates
}

# Wait and collect
$allResults = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -Wait
    $allResults += $result
    Remove-Job -Job $job
}

$overallSw.Stop()
$totalMs = $overallSw.ElapsedMilliseconds

# Aggregate
$success200 = ($allResults | Where-Object { $_.Status -eq 200 }).Count
$success202 = ($allResults | Where-Object { $_.Status -eq 202 }).Count
$errorCount = ($allResults | Where-Object { $_.Status -ne 200 -and $_.Status -ne 202 }).Count
$totalSuccess = $success200 + $success202

$latencies = $allResults | Sort-Object LatencyMs | Select-Object -ExpandProperty LatencyMs
$count = $latencies.Count

if ($count -gt 0) {
    $p50Idx = [math]::Floor($count * 0.50)
    $p95Idx = [math]::Floor($count * 0.95)
    $p99Idx = [math]::Floor($count * 0.99)
    if ($p50Idx -ge $count) { $p50Idx = $count - 1 }
    if ($p95Idx -ge $count) { $p95Idx = $count - 1 }
    if ($p99Idx -ge $count) { $p99Idx = $count - 1 }

    $p50 = $latencies[$p50Idx]
    $p95 = $latencies[$p95Idx]
    $p99 = $latencies[$p99Idx]
    $minLat = $latencies[0]
    $maxLat = $latencies[-1]
} else {
    $p50 = $p95 = $p99 = $minLat = $maxLat = 0
}

$tps = if ($totalMs -gt 0) { [math]::Round($Total * 1000 / $totalMs, 1) } else { 0 }

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Total requests:  $Total"
Write-Host "Duration:        $totalMs ms"
Write-Host ""
Write-Host "Throughput:      $tps req/s" -ForegroundColor $(if ($tps -ge 100) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Success (200):   $success200"
Write-Host "Async (202):     $success202"
Write-Host "Errors:          $errorCount"
Write-Host ""
Write-Host "Latency:" -ForegroundColor White
Write-Host "  Min:    $minLat ms"
Write-Host "  P50:    $p50 ms"
Write-Host "  P95:    $p95 ms"
Write-Host "  P99:    $p99 ms"
Write-Host "  Max:    $maxLat ms"

Write-Host ""
if ($tps -ge 100) {
    Write-Host "PASS: $tps TPS >= 100 TPS target" -ForegroundColor Green
} else {
    Write-Host "FAIL: $tps TPS < 100 TPS target" -ForegroundColor Red
}

if ($errorCount -gt 0) {
    Write-Host "WARNING: $errorCount errors during test" -ForegroundColor Yellow
}
