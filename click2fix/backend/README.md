# Click2Fix Backend

Node.js, Express, TypeScript API for Click2Fix.

## API Prefix

Routes are mounted both at `/api/*` and at the root path so hackathon clients can use the exact product prompt paths:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/verify-otp`
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

## Production Replacements

- Replace dev OTP with Firebase or Twilio.
- Replace payment mock order creation with Razorpay order API and webhook verification.
- Replace local media URLs with S3 signed uploads.
- Add Redis Socket.IO adapter for multi-instance deployments.
- Add audit logging to all admin and payment transitions.

