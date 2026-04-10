# Click2Fix Backend

Node.js, Express, TypeScript API for Click2Fix.

## API Prefix

Routes are mounted both at `/api/*` and at the root path so hackathon clients can use the exact product prompt paths:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/verify-otp`
- `POST /auth/firebase-login`
- `POST /auth/logout`
- `POST /ai/detect-issue`
- `POST /ai/predict-price`
- `GET /worker/nearby`
- `POST /worker/send-quote`
- `POST /worker/update-location`
- `POST /worker/set-availability`
- `POST /booking/create`
- `GET /booking/history`
- `GET /booking/live-location`
- `POST /booking/complete`
- `POST /payment/pay`
- `POST /payment/verify`
- `POST /review/add`
- `POST /notifications/register-token`
- `POST /notifications/unregister-token`
- `POST /notifications/send-test`
- `POST /notifications/send` (admin only)
- `GET /admin/dashboard`
- `GET /admin/workers/pending`
- `POST /admin/approve-worker`

## Run

```bash
npm install
cp .env.example .env
npm run dev
```

In development, OTP uses `123456` and booking completion OTP uses `432198`.

## Firebase Setup

Add these environment variables in `backend/.env`:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (use escaped newlines: `\\n`)
- `FIREBASE_STORAGE_BUCKET` (optional)
- `FIREBASE_DATABASE_URL` (optional)

When Firebase is configured, backend supports:

- Firebase ID token login via `/auth/firebase-login`
- FCM push notifications to registered device tokens
- Firestore mirroring of push notification events (`notifications` collection)

## Production Replacements

- Replace dev OTP fallback with phone provider verification (Firebase Auth phone or Twilio Verify).
- Replace payment mock order creation with Razorpay order API and webhook verification.
- Replace local media URLs with S3 signed uploads.
- Add Redis Socket.IO adapter for multi-instance deployments.
- Add audit logging to all admin and payment transitions.

