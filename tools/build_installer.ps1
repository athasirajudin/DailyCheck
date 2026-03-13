param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
$issPath = Join-Path $projectRoot "installer.iss"

if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml tidak ditemukan: $pubspecPath"
}
if (-not (Test-Path $issPath)) {
    throw "installer.iss tidak ditemukan: $issPath"
}

$pubspec = Get-Content $pubspecPath -Raw
$match = [regex]::Match($pubspec, "(?m)^\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+[0-9]+)?\s*$")
if (-not $match.Success) {
    throw "Tidak bisa baca versi dari pubspec.yaml (format version tidak valid)."
}
$appVersion = $match.Groups[1].Value

if (-not $SkipBuild) {
    Write-Host "==> Build Flutter Windows (release)..."
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build windows --release gagal."
    }
}

$isccCandidates = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)
$isccPath = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $isccPath) {
    throw "ISCC.exe tidak ditemukan. Install Inno Setup 6 dulu."
}

Write-Host "==> Compile installer (version: $appVersion)..."
& $isccPath "/DMyAppVersion=$appVersion" $issPath
if ($LASTEXITCODE -ne 0) {
    throw "Compile installer gagal."
}

$outputFile = Join-Path $projectRoot "output\DailyCheck-Setup-$appVersion.exe"
Write-Host "Selesai. Installer:"
Write-Host $outputFile
