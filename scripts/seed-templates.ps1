# scripts/seed-templates.ps1
# Seeds all .typ templates into PostgreSQL and Redis.
# Usage: .\scripts\seed-templates.ps1
# Requires: docker must be running with postgres and redis containers up.

param(
    [string]$PostgresContainer = "",
    [string]$RedisContainer = ""
)

$ErrorActionPreference = "Stop"
$repoDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Auto-detect container names
if (-not $PostgresContainer) {
    $PostgresContainer = (docker ps --filter "ancestor=postgres:16-alpine" --format "{{.Names}}" | Select-Object -First 1)
    if (-not $PostgresContainer) {
        $PostgresContainer = (docker ps --filter "name=postgres" --format "{{.Names}}" | Select-Object -First 1)
    }
}
if (-not $RedisContainer) {
    $RedisContainer = (docker ps --filter "ancestor=redis:7-alpine" --format "{{.Names}}" | Select-Object -First 1)
    if (-not $RedisContainer) {
        $RedisContainer = (docker ps --filter "name=redis" --format "{{.Names}}" | Select-Object -First 1)
    }
}

Write-Host "Using Postgres container: $PostgresContainer" -ForegroundColor DarkGray
Write-Host "Using Redis container: $RedisContainer" -ForegroundColor DarkGray
Write-Host ""

$templatesDir = Join-Path $repoDir "templates"
$seeded = 0

Get-ChildItem -Path $templatesDir -Directory | ForEach-Object {
    $form = $_.Name
    Get-ChildItem -Path $_.FullName -Filter "*.typ" | ForEach-Object {
        $version = $_.BaseName
        # Strip leading 'v' from version if present
        if ($version.StartsWith("v")) { $version = $version.Substring(1) }

        $source = Get-Content -Path $_.FullName -Raw
        # Escape single quotes for SQL
        $sqlSource = $source -replace "'", "''"

        Write-Host "Seeding: form=$form version=$version from $($_.Name)" -ForegroundColor Yellow

        # Insert into PostgreSQL
        $sql = @"
INSERT INTO templates (form, version, typ_source, schema, active)
VALUES ('$form', '$version', E'$sqlSource', '{}', true)
ON CONFLICT (form, version) DO UPDATE SET typ_source = EXCLUDED.typ_source;
"@
        $sql | docker exec -i $PostgresContainer psql -U pdfgen -d pdfgen 2>&1 | Out-Null

        # Warm Redis cache via file + redis-cli -x (avoids shell escaping issues)
        $redisKey = "template:${form}:${version}"
        $tmpFile = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($tmpFile, $source)
        docker cp $tmpFile "${RedisContainer}:/tmp/_seed_template.typ" 2>&1 | Out-Null
        docker exec $RedisContainer sh -c "cat /tmp/_seed_template.typ | redis-cli -x SET `"$redisKey`"" 2>&1 | Out-Null
        Remove-Item $tmpFile -ErrorAction SilentlyContinue

        Write-Host "  -> OK" -ForegroundColor Green
        $script:seeded++
    }
}

Write-Host ""
Write-Host "Seeded $seeded templates successfully." -ForegroundColor Green
