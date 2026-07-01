# Digivla IDS 2.0 — Mobile

Flutter app for Digivla IDS: login, dashboard, media, articles (TV / Radio / Online), QC, user management, and uploads.

## Requirements

- Flutter SDK 3.16+ (`flutter doctor`)
- Backend V2 API running (default VM: `http://192.168.100.50:8005`)

## Setup

```bash
cd digivla_mobile
flutter pub get
```

## API URL

| Environment | URL |
|-------------|-----|
| LAN (VM) | `http://192.168.100.50:8005` |

```bash
# LAN — physical device on same WiFi as VM
flutter run --dart-define=API_BASE_URL=http://192.168.100.50:8005

# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8005
```

## Build APK (Windows)

```powershell
# LAN
$env:API_BASE_URL = "http://192.168.100.50:8005"
.\build-apk.ps1
```

Output: `releases/digivla-mobile.apk`

## Test accounts (VM)

| Username | Password | Role |
|----------|----------|------|
| superadmin | superadmin123 | superadmin |
| admin | admin123 | admin |
| online | online123 | staff_online |
| tvradio | tvradio123 | staff_tv_radio |
| analis | analis123 | analis |

## Features

- JWT login with secure token storage
- RBAC aligned with web (roles, route guards, QC, user management)
- Dashboard stats, media CRUD, article lists & upload
- Server connection test on login screen
- Responsive layout for small screens

## Troubleshooting login

1. Use **Test koneksi server** on the login screen.
2. Physical device must be on **same WiFi** as VM for LAN builds (`192.168.100.x`).
