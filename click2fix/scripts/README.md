# Scripts

## Build Release Artifacts

Build Android APK for user app:

```powershell
./scripts/build_release.ps1 -ApiBaseUrl https://api.your-domain.com -SocketUrl https://api.your-domain.com -UserAndroidApk
```

Build all supported artifacts on the current machine:

```powershell
./scripts/build_release.ps1 -ApiBaseUrl https://api.your-domain.com -SocketUrl https://api.your-domain.com -All
```

The output goes to `dist/`.

## Stop Local Services

```powershell
./scripts/stop_local_services.ps1
```

