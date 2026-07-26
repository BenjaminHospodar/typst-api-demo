# scripts/test-functional.ps1
# Functional tests for the PDF generation pipeline (Windows PowerShell version)
# Usage: .\scripts\test-functional.ps1 [-BaseUrl http://localhost:8080]

param(
    [string]$BaseUrl = "http://localhost:8080"
)

$pass = 0
$fail = 0
$errors = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Url,
        [string]$Body = $null,
        [int[]]$ExpectedStatus = @(200)
    )

    try {
        $params = @{
            Uri = $Url
            Method = $Method
            ContentType = "application/json"
            ErrorAction = "Stop"
            UseBasicParsing = $true
        }
        if ($Body) { $params.Body = $Body }

        $response = Invoke-WebRequest @params
        $status = $response.StatusCode

        if ($ExpectedStatus -contains $status) {
            Write-Host "  PASS: $Name (HTTP $status)" -ForegroundColor Green
            $script:pass++
            return $response
        } else {
            Write-Host "  FAIL: $Name (expected $($ExpectedStatus -join '|'), got $status)" -ForegroundColor Red
            $script:fail++
            $script:errors += $Name
            return $null
        }
    } catch {
        $status = 0
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($ExpectedStatus -contains $status) {
            Write-Host "  PASS: $Name (HTTP $status)" -ForegroundColor Green
            $script:pass++
            return $null
        } else {
            Write-Host "  FAIL: $Name (expected $($ExpectedStatus -join '|'), got $status / $($_.Exception.Message))" -ForegroundColor Red
            $script:fail++
            $script:errors += $Name
            return $null
        }
    }
}

Write-Host "=== PDF Generation Pipeline - Functional Tests ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health
Write-Host "1. Health check" -ForegroundColor White
Test-Endpoint -Name "Health" -Url "$BaseUrl/api/v1/health"

# Test 2: Invoice v2.1.0
Write-Host "2. Invoice v2.1.0 (sync)" -ForegroundColor White
$body = '{"form":"invoice","version":"2.1.0","fields":{"name":"Acme Corp","date":"2024-04-13","text1":"Consulting","text3":"Net 30","text4":"Wire"}}'
$resp = Test-Endpoint -Name "Invoice v2.1.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)
if ($resp -and $resp.StatusCode -eq 200) {
    $bytes = $resp.Content
    if ($resp.Headers["Content-Type"] -match "pdf") {
        Write-Host "    -> Valid PDF response ($($resp.RawContentLength) bytes)" -ForegroundColor DarkGreen
    }
}

# Test 3: Invoice v2.0.0
Write-Host "3. Invoice v2.0.0" -ForegroundColor White
$body = '{"form":"invoice","version":"2.0.0","fields":{"name":"Test","date":"2024-01-01","text1":"Hello"}}'
Test-Endpoint -Name "Invoice v2.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 4: Report v2.0.0
Write-Host "4. Report v2.0.0 (tables + columns)" -ForegroundColor White
$body = '{"form":"report","version":"2.0.0","fields":{"name":"GlobalTech","date":"2024-12-31","text1":"Great year","text3":"Growth ahead"}}'
Test-Endpoint -Name "Report v2.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 5: Contract v1.0.0
Write-Host "5. Contract v1.0.0 (multi-page)" -ForegroundColor White
$body = '{"form":"contract","version":"1.0.0","fields":{"name":"MegaCorp","date":"2024-06-15","text1":"Dev services"}}'
Test-Endpoint -Name "Contract v1.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 6: Dashboard v1.0.0
Write-Host "6. Dashboard v1.0.0 (KPI cards)" -ForegroundColor White
$body = '{"form":"dashboard","version":"1.0.0","fields":{"name":"Metrics Co","date":"2024-04-13","text1":"Record month","text3":"Board meeting soon"}}'
Test-Endpoint -Name "Dashboard v1.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 7: Minimal template
Write-Host "7. Minimal template (fast path)" -ForegroundColor White
$body = '{"form":"minimal","version":"1.0.0","fields":{"name":"Speed","date":"2024-04-13"}}'
Test-Endpoint -Name "Minimal v1.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 8: Legal v1.0.0 (4-page doc with charts/graphs)
Write-Host "8. Legal v1.0.0 (4-page legal doc)" -ForegroundColor White
$body = '{"form":"legal","version":"1.0.0","fields":{"name":"Morrison Partners LLP","date":"2026-04-13","text1":"Risk Assessment Memo","text2":"State of Delaware","text3":"Apex Holdings","text4":"Zenith Capital","text5":"CASE-2026-001","text6":"Comprehensive legal analysis of the proposed transaction.","text7":"Risk landscape dominated by regulatory uncertainty.","text8":"Maximum exposure estimated at USD 5.45 million.","text9":"HSR filing and CFIUS notice required.","text10":"All regulatory approvals and due diligence completion.","text11":"Quarterly covenant testing and key personnel retention.","text12":"Environmental remediation subject to separate indemnification."}}'
Test-Endpoint -Name "Legal v1.0.0" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(200, 202)

# Test 9: Missing template
Write-Host "9. Missing template (expect 404)" -ForegroundColor White
$body = '{"form":"nonexistent","version":"9.9.9","fields":{"name":"X"}}'
Test-Endpoint -Name "Missing template" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body $body -ExpectedStatus @(404)

# Test 10: Invalid request
Write-Host "10. Invalid request (expect 400)" -ForegroundColor White
Test-Endpoint -Name "Invalid request" -Method "POST" -Url "$BaseUrl/api/v1/generate" -Body '{"form":"","version":""}' -ExpectedStatus @(400)

# Test 11: Invalid poll
Write-Host "11. Invalid job poll (expect 404)" -ForegroundColor White
Test-Endpoint -Name "Invalid job poll" -Url "$BaseUrl/api/v1/jobs/FAKEID/result" -ExpectedStatus @(404)

# Summary
Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Passed: $pass" -ForegroundColor Green
if ($fail -gt 0) {
    Write-Host "Failed: $fail" -ForegroundColor Red
    Write-Host "Failures:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "All tests passed!" -ForegroundColor Green
}
