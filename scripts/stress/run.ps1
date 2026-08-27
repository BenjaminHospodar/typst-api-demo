param(
    [ValidateSet("generate", "errors", "sidecar-kill", "rabbit-flood")]
    [string]$Scenario = "generate",
    [string]$BaseUrl = $(if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:8080" })
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$env:BASE_URL = $BaseUrl

switch ($Scenario) {
    "sidecar-kill" {
        docker compose stop rust-compiler
        try {
            k6 run (Join-Path $here "sidecar-kill.js")
        } finally {
            docker compose start rust-compiler
        }
    }
    default {
        k6 run (Join-Path $here "$Scenario.js")
    }
}
