# API Contract

Routes are available at both `/api/*` and the exact product paths below.

## Authentication

`POST /auth/register`

Body:

```json
{
  "role": "user",
  "name": "Asha",
  "phone": "9876543210",
  "email": "asha@example.com",
  "password": "optional-password"
}
```

`POST /auth/login`

Body:

```json
{
  "role": "user",
  "phone": "9876543210"
}
```

`POST /auth/verify-otp`

Body:

```json
{
  "role": "user",
  "phone": "9876543210",
  "otp": "123456",
  "deviceId": "device-001"
}
```

`POST /auth/logout`

Auth: user, worker, admin.

## AI

`POST /ai/detect-issue`

Auth: user, worker, admin.

Body:

```json
{
  "description": "Kitchen pipe leaking",
  "imageUrl": "https://example.com/issue.jpg",
  "latitude": 13.0827,
  "longitude": 80.2707
}
```

`POST /ai/predict-price`

Auth: user, worker, admin.

Body:

```json
{
  "category": "plumbing",
  "city": "Chennai",
  "urgency": "high",
  "workerHistoryCount": 25
}
```

## Issues

`POST /issues`

Auth: user.

Body:

```json
{
  "description": "Kitchen pipe leaking",
  "latitude": 13.0827,
  "longitude": 80.2707,
  "isEmergency": false
}
```

`GET /issues/:id`

Auth: user, worker, admin.

## Worker

`GET /worker/nearby?issueId=<uuid>&radiusKm=5`

Auth: user, worker, admin.

`POST /worker/send-quote`

Auth: worker.

Body:

```json
{
  "issueId": "00000000-0000-0000-0000-000000000000",
  "price": 450,
  "estimatedTime": 30,
  "arrivalTime": "2026-04-10T12:00:00.000Z",
  "message": "I can arrive in 30 minutes."
}
```

`POST /worker/update-location`

Auth: worker.

Body:

```json
{
  "latitude": 13.0827,
  "longitude": 80.2707
}
```

`POST /worker/set-availability`

Auth: worker.

Body:

```json
{
  "availability": true
}
```

## Booking

`POST /booking/create`

Auth: user.

Body:

```json
{
  "issueId": "00000000-0000-0000-0000-000000000000",
  "workerId": "00000000-0000-0000-0000-000000000000",
  "quotationId": "00000000-0000-0000-0000-000000000000"
}
```

`GET /booking/history`

Auth: user or worker.

`GET /booking/live-location?bookingId=<uuid>`

Auth: user or worker.

`POST /booking/complete`

Auth: user or worker.

Body:

```json
{
  "bookingId": "00000000-0000-0000-0000-000000000000",
  "completionOtp": "432198"
}
```

## Payment

`POST /payment/pay`

Auth: user.

`POST /payment/verify`

Auth: user.

## Review

`POST /review/add`

Auth: user.

## Admin

`GET /admin/dashboard`

Auth: admin.

`GET /admin/workers/pending`

Auth: admin.

`POST /admin/approve-worker`

Auth: admin.

