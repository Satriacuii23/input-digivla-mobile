# Build Digivla mobile APK (Flutter — bukan Expo)
# API: https://input-digivla.ngrok.app (testing dari luar jaringan)

$ErrorActionPreference = "Stop"
$Flutter = "C:\Tools\flutter\bin\flutter.bat"
$MobileDir = $PSScriptRoot
$OutDir = Join-Path $MobileDir "releases"
$ApiUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "https://input-digivla.ngrok.app" }

Push-Location (Join-Path $MobileDir "digivla_mobile")
& $Flutter pub get
& $Flutter build apk --release --dart-define=API_BASE_URL=$ApiUrl

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$apk = Join-Path $MobileDir "digivla_mobile\build\app\outputs\flutter-apk\app-release.apk"
$dest = Join-Path $OutDir "digivla-mobile.apk"
Copy-Item $apk $dest -Force
Write-Host ""
Write-Host "APK: $dest"
Write-Host "API: $ApiUrl"
Pop-Location
