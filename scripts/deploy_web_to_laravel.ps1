param(
    [string]$ApiBaseUrl = "https://tony-aforethought-tonishly.ngrok-free.dev",
    [string]$LaravelPublicPath = "C:\laragon\www\absensi1\gagal ke 2\backend_laravel\public"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildOutput = Join-Path $projectRoot "build\web"

Write-Host "Building Flutter Web with API_BASE_URL=$ApiBaseUrl"
Push-Location $projectRoot
try {
    flutter build web --release --dart-define="API_BASE_URL=$ApiBaseUrl"
}
finally {
    Pop-Location
}

Write-Host "Syncing Flutter build to Laravel public folder: $LaravelPublicPath"

$itemsToCopy = @(
    "assets",
    "canvaskit",
    "icons",
    "favicon.png",
    "flutter.js",
    "flutter_bootstrap.js",
    "flutter_service_worker.js",
    "index.html",
    "main.dart.js",
    "manifest.json",
    "version.json"
)

foreach ($item in $itemsToCopy) {
    $source = Join-Path $buildOutput $item
    $destination = Join-Path $LaravelPublicPath $item

    if (-not (Test-Path $source)) {
        continue
    }

    if (Test-Path $destination) {
        Remove-Item $destination -Recurse -Force
    }

    Copy-Item $source $destination -Recurse -Force
}

Write-Host "Flutter Web deployed to Laravel public successfully."
