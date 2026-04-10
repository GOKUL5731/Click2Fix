# Distribution Guide

This guide turns Click2Fix into installable builds that other people can install and use.

## 1. Deploy the Backend First

Do this before building the apps for public users. A released app cannot use `localhost`.

Required public services:

- Backend API: `https://api.your-click2fix-domain.com`
- Socket.IO endpoint: same domain or another HTTPS domain.
- PostgreSQL database.
- Redis.
- AI service.
- Object storage for uploads and invoices.
- OTP provider such as Firebase or Twilio.
- Payment provider such as Razorpay.

For a hackathon demo, you can use a temporary HTTPS tunnel or cloud server. For a real public launch, use AWS, Azure, or another production host.

## 2. Install Build Tools

On Windows for Android and Windows desktop builds:

- Flutter SDK.
- Android Studio with Android SDK and command line tools.
- Java JDK.
- Visual Studio Build Tools with the Desktop development with C++ workload for Windows desktop builds.

Check:

```powershell
flutter doctor
flutter doctor --android-licenses
```

For iOS:

- macOS.
- Xcode.
- Apple Developer account.
- Signing certificate and provisioning profile.

## 3. Generate Platform Folders

The release script handles this automatically. If you want to do it manually:

```powershell
cd mobile_app
flutter create --project-name click2fix_mobile_app --org com.click2fix --platforms=android,ios,windows .

cd ../worker_app
flutter create --project-name click2fix_worker_app --org com.click2fix --platforms=android,windows .

cd ../admin_panel
flutter create --project-name click2fix_admin_panel --org com.click2fix --platforms=web .
```

## 4. Build Android APK for Direct Sharing

APK is easiest for direct install outside the Play Store.

```powershell
./scripts/build_release.ps1 `
  -ApiBaseUrl https://api.your-click2fix-domain.com `
  -SocketUrl https://api.your-click2fix-domain.com `
  -UserAndroidApk `
  -WorkerAndroidApk
```

Outputs:

```text
dist/click2fix-user-android-release.apk
dist/click2fix-worker-android-release.apk
```

People can install APK files on Android after enabling install from unknown sources. For broad public release, prefer Play Store distribution.

## 5. Build Android App Bundle for Play Store

```powershell
./scripts/build_release.ps1 `
  -ApiBaseUrl https://api.your-click2fix-domain.com `
  -SocketUrl https://api.your-click2fix-domain.com `
  -UserAndroidAab `
  -WorkerAndroidAab
```

Outputs:

```text
dist/click2fix-user-android-release.aab
dist/click2fix-worker-android-release.aab
```

Before Play Store upload:

- Configure app icon and splash screen.
- Configure app signing.
- Add privacy policy URL.
- Add permission descriptions for camera, location, photos, microphone, phone, and notifications.
- Replace dev OTP, payment, and storage integrations.

## 6. Build Windows Desktop App

```powershell
./scripts/build_release.ps1 `
  -ApiBaseUrl https://api.your-click2fix-domain.com `
  -SocketUrl https://api.your-click2fix-domain.com `
  -UserWindows `
  -WorkerWindows
```

Outputs:

```text
dist/click2fix-user-windows/
dist/click2fix-worker-windows/
```

For a polished installer, package the release folder with MSIX, Inno Setup, or WiX after the Flutter Windows build succeeds.

## 7. Build Admin Web Panel

```powershell
./scripts/build_release.ps1 `
  -ApiBaseUrl https://api.your-click2fix-domain.com `
  -AdminWeb
```

Output:

```text
dist/admin-panel-web/
```

Upload the folder to S3/CloudFront, Azure Static Web Apps, Firebase Hosting, Netlify, or another static host. Protect the panel with admin login and backend RBAC.

## 8. Build iOS

iOS must be built on macOS:

```bash
cd mobile_app
flutter create --project-name click2fix_mobile_app --org com.click2fix --platforms=ios .
flutter pub get
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.your-click2fix-domain.com \
  --dart-define=SOCKET_URL=https://api.your-click2fix-domain.com \
  --dart-define=ENVIRONMENT=production
```

Then upload the IPA through Xcode Organizer or Transporter.

## 9. Public Launch Checklist

- Deploy backend and AI service over HTTPS.
- Use production PostgreSQL and Redis.
- Configure Firebase or Twilio OTP.
- Configure Razorpay and webhook verification.
- Configure Google Maps API keys.
- Configure upload storage with signed URLs.
- Add privacy policy and terms.
- Add Android and iOS permissions.
- Add app icons, launcher name, and splash screens.
- Add crash reporting and analytics.
- Create admin user and RBAC policy.
- Run security review for Aadhaar, face photos, payments, and location data.

