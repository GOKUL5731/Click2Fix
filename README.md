# Click2Fix

Click2Fix is an AI-powered home repair and service marketplace.

Tagline: "Click the problem. Fix it instantly."

This repository contains a production-minded hackathon scaffold for:

- Flutter user app for Android, iOS, and Windows
- Flutter worker app
- Flutter web admin panel
- Node.js, Express, TypeScript backend
- Python FastAPI AI service
- PostgreSQL schema and database design
- Docker-based local deployment starter
- Product architecture, wireframes, flows, and roadmap docs

## Product Flow

1. User logs in with mobile OTP and optional face verification.
2. User uploads an issue by photo, video, voice, or text.
3. AI detects category, urgency, and estimated price.
4. Backend searches verified nearby workers by skill, location, rating, trust score, and availability.
5. Workers receive the request in real time and submit quote plus arrival time.
6. User compares quotes and confirms a booking.
7. Live tracking, chat, payment, review, and invoice complete the job.
8. Admin panel monitors workers, bookings, fraud, revenue, and emergencies.

## Repository Layout

```text
click2fix/
|-- mobile_app/
|-- worker_app/
|-- admin_panel/
|-- backend/
|-- ai_service/
|-- database/
|-- docs/
|-- deployment/
```

## MVP Targets

- Login and OTP verification
- Upload household issue
- AI category and urgency detection
- Nearby worker list
- Quotation comparison
- Booking creation
- Socket.IO tracking and booking status events
- Emergency request path
- Admin worker approval queue

## Local Development

Backend:

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

AI service:

```bash
cd ai_service
python -m venv .venv
.venv/Scripts/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

Database:

```bash
psql -d click2fix -f database/schema.sql
```

Docker compose:

```bash
cd deployment
docker compose up --build
```

Flutter apps are intentionally lightweight scaffolds. Create full Flutter platforms with `flutter create .` inside each app folder before running on device, then keep the existing `lib/` files.

## Google Maps Setup (Mobile and Worker Apps)

Google Maps widgets are integrated in `mobile_app` and `worker_app` using `google_maps_flutter`.

1. Generate platform folders if they are missing:

```bash
cd mobile_app
flutter create . --platforms android,ios,web
cd ../worker_app
flutter create . --platforms android,ios,web
```

2. Android key setup in both apps:  
Add this inside `<application>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

3. iOS key setup in both apps:  
In `ios/Runner/AppDelegate.swift`, add:

```swift
import GoogleMaps
```

and call:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

4. Web key setup in both apps:  
In `web/index.html`, include the Google Maps JavaScript SDK script tag with your key.

5. Run with Dart defines:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

## Firebase Backend and Notifications

Backend now supports Firebase Auth login and FCM push delivery.

1. Set backend env variables in `backend/.env`:

```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_DATABASE_URL=
```

2. Use Firebase login endpoint:

- `POST /auth/firebase-login` with:
  ```json
  {
    "role": "user",
    "idToken": "<firebase-id-token>"
  }
  ```

3. Register device tokens after login:

- `POST /notifications/register-token`
- `POST /notifications/unregister-token`

4. Send a test push to the logged-in actor:

- `POST /notifications/send-test`

5. Flutter app setup for notifications (`mobile_app` and `worker_app`):

- Add Android file: `android/app/google-services.json`
- Add iOS file: `ios/Runner/GoogleService-Info.plist`
- For web, pass these Dart defines:
  - `FIREBASE_WEB_API_KEY`
  - `FIREBASE_WEB_APP_ID`
  - `FIREBASE_WEB_MESSAGING_SENDER_ID`
  - `FIREBASE_WEB_PROJECT_ID`

Example:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY \
  --dart-define=FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY \
  --dart-define=FIREBASE_WEB_APP_ID=YOUR_FIREBASE_WEB_APP_ID \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=YOUR_FIREBASE_WEB_MESSAGING_SENDER_ID \
  --dart-define=FIREBASE_WEB_PROJECT_ID=YOUR_FIREBASE_WEB_PROJECT_ID
```

## Build Installable Apps

After deploying a public HTTPS backend and installing Flutter:

```powershell
./scripts/build_release.ps1 `
  -ApiBaseUrl https://api.your-click2fix-domain.com `
  -SocketUrl https://api.your-click2fix-domain.com `
  -UserAndroidApk
```

See `docs/release/distribution_guide.md` for Android APK/AAB, Windows, iOS, and admin web distribution steps.