# scripts/test-load-fast.ps1
# High-performance load test using .NET HttpClient with true async concurrency
# Usage: .\scripts\test-load-fast.ps1 [-Concurrency 50] [-Total 1000] [-BaseUrl http://localhost:8080]

param(
    [int]$Concurrency = 50,
    [int]$Total = 1000,
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

Write-Host "=== PDF Generation - High-Performance Load Test ===" -ForegroundColor Cyan
Write-Host "Concurrency: $Concurrency"
Write-Host "Total requests: $Total"
Write-Host "Target: $endpoint"
Write-Host ""

# Increase connection limit for high concurrency
[System.Net.ServicePointManager]::DefaultConnectionLimit = $Concurrency + 20

# Use Runspace Pool for true in-process parallel execution (no Start-Job overhead)
$scriptBlock = {
    param($endpoint, $body)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $req = [System.Net.HttpWebRequest]::Create($endpoint)
        $req.Method = "POST"
        $req.ContentType = "application/json"
        $req.Timeout = 30000
        $req.KeepAlive = $true
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $req.ContentLength = $bytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
        $resp = $req.GetResponse()
        $sw.Stop()
        $status = [int]([System.Net.HttpWebResponse]$resp).StatusCode
        $resp.Close()
        return "$status $($sw.ElapsedMilliseconds)"
    } catch [System.Net.WebException] {
        $sw.Stop()
        $status = 0
        if ($_.Exception.Response) {
            $status = [int]([System.Net.HttpWebResponse]$_.Exception.Response).StatusCode
        }
        return "$status $($sw.ElapsedMilliseconds)"
    } catch {
        $sw.Stop()
        return "0 $($sw.ElapsedMilliseconds)"
    }
}

Write-Host "Running with RunspacePool ($Concurrency threads)..." -ForegroundColor Yellow

$pool = [RunspaceFactory]::CreateRunspacePool(1, $Concurrency)
$pool.Open()

$overallSw = [System.Diagnostics.Stopwatch]::StartNew()

$handles = @()
for ($i = 0; $i -lt $Total; $i++) {
    $body = $templates[$i % $templates.Count]
    $ps = [PowerShell]::Create().AddScript($scriptBlock).AddArgument($endpoint).AddArgument($body)
    $ps.RunspacePool = $pool
    $handles += @{ PS = $ps; Handle = $ps.BeginInvoke() }
}

# Collect results
$allResults = @()
foreach ($h in $handles) {
    $allResults += $h.PS.EndInvoke($h.Handle)
    $h.PS.Dispose()
}
$overallSw.Stop()
$pool.Close()

$totalMs = $overallSw.ElapsedMilliseconds
$s200 = 0; $s202 = 0; $errs = 0; $latencies = @()
foreach ($r in $allResults) {
    $parts = $r -split ' '
    $st = [int]$parts[0]
    $lat = [int]$parts[1]
    $latencies += $lat
    if ($st -eq 200) { $s200++ } elseif ($st -eq 202) { $s202++ } else { $errs++ }
}
$latencies = $latencies | Sort-Object
$c = $latencies.Count
$tps = if ($totalMs -gt 0) { [math]::Round($Total * 1000.0 / $totalMs, 1) } else { 0 }

if ($c -gt 0) {
    $p50 = $latencies[[math]::Floor($c * 0.50)]
    $p95 = $latencies[[math]::Floor($c * 0.95)]
    $p99 = $latencies[[math]::Min($c - 1, [math]::Floor($c * 0.99))]
    $minLat = $latencies[0]
    $maxLat = $latencies[-1]
} else {
    $p50 = $p95 = $p99 = $minLat = $maxLat = 0
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Total requests:  $Total"
Write-Host "Duration:        $totalMs ms"
Write-Host ""
Write-Host "Throughput:      $tps req/s" -ForegroundColor $(if ($tps -ge 100) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Success (200):   $s200"
Write-Host "Async (202):     $s202"
Write-Host "Errors:          $errs"
Write-Host ""
Write-Host "Latency:" -ForegroundColor White
Write-Host "  Min:    $minLat ms"
Write-Host "  P50:    $p50 ms"
Write-Host "  P95:    $p95 ms"
Write-Host "  P99:    $p99 ms"
Write-Host "  Max:    $maxLat ms"

if ($tps -ge 100) {
    Write-Host ""
    Write-Host "PASS: $tps TPS >= 100 TPS target" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "BELOW TARGET: $tps TPS < 100 TPS target" -ForegroundColor Yellow
}
