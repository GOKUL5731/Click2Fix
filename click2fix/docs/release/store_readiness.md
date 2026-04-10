# Store Readiness

## Android

Required before Play Store:

- Unique package IDs:
  - User app: `com.click2fix.click2fix_mobile_app`
  - Worker app: `com.click2fix.click2fix_worker_app`
- Signed release builds.
- App icon and feature graphic.
- Privacy policy.
- Data safety form.
- Camera, location, photos, microphone, notification, and phone permission explanations.
- Test login that does not expose real OTP credentials.
- Demo worker and demo user accounts.

## iOS

Required before App Store:

- Apple Developer account.
- Bundle ID and app signing.
- Privacy nutrition labels.
- Permission text in `Info.plist`.
- TestFlight build.
- App review demo account.

## Windows

Recommended:

- MSIX installer.
- Code signing certificate.
- Windows app icon.
- Public backend URL.
- Auto-update strategy.

## Reality Check

The current repository is a hackathon MVP scaffold. It can be made installable once Flutter platform projects are generated and build tools are installed, but “anyone can install and use” also requires a public backend, database, Redis, OTP, payments, and storage. Without those services, the app can open but production workflows cannot complete.

