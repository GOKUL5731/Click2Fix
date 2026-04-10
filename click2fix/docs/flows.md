# Authentication, AI, Booking, and Real-Time Flows

## User Registration Flow

1. User enters phone number.
2. Backend rate-limits by IP, phone, and device ID.
3. Backend creates OTP challenge and stores hashed OTP in Redis.
4. OTP provider sends the code through Firebase or Twilio.
5. User submits OTP.
6. Backend validates OTP, creates or updates user, binds device, issues JWT access token and refresh token.
7. User may upload face photo.
8. Backend stores the file in object storage and calls AI face verification.
9. User profile stores `face_verified` and verification audit metadata.

## Worker Registration Flow

1. Worker enters phone number and verifies OTP.
2. Worker submits profile, skills, experience, service area, and working hours.
3. Worker uploads Aadhaar image and selfie.
4. Backend validates upload type and size, stores files in object storage, and calls AI face verification.
5. Admin reviews pending workers.
6. Approved workers can toggle availability and receive requests.

## Issue Upload and AI Detection Flow

1. User uploads image, video, voice transcript, or text description.
2. Backend validates media and creates an `issues` row with `status = ai_pending`.
3. Backend calls AI service with media URL, description, and location.
4. AI returns category, confidence, urgency, and price range.
5. Backend updates issue and creates notification if emergency.
6. User sees editable AI result.

## Nearby Worker Search Flow

1. User requests nearby workers for an issue.
2. Backend filters workers by:
   - Verification status
   - Availability
   - Matching skill/category
   - Service radius
   - Distance within 2 km, 5 km, or 10 km
   - Rating and trust score threshold
   - Blacklist status
3. Backend ranks workers by weighted score:
   - Distance: 30 percent
   - Rating: 20 percent
   - Trust score: 20 percent
   - Availability recency: 15 percent
   - Acceptance rate: 15 percent
4. Backend emits `worker.requested` to matching workers.

## Quotation Flow

1. Worker opens request detail.
2. Worker submits price, arrival time, and message.
3. Backend validates the worker is eligible for the issue.
4. Backend stores quotation and emits `quote.created` to the user.
5. User compares quotes by price, rating, distance, arrival time, and trust score.

## Booking Flow

1. User selects a quote or emergency worker.
2. Backend creates booking with `booking_status = confirmed`.
3. Backend locks the selected quotation.
4. Backend notifies worker and user.
5. Booking room opens for chat and tracking.
6. Worker updates status: accepted, on the way, arrived, work started, completed.
7. Completion OTP is verified.
8. User pays.
9. Backend verifies payment and generates invoice.
10. User submits review.

## Emergency Flow

1. User taps Emergency Fix.
2. User selects type or AI marks issue as emergency.
3. Backend creates priority issue and notifies nearest verified workers immediately.
4. User sees nearest workers and can start instant booking.
5. Admin emergency room receives `emergency.created`.
6. Backend escalates if no worker accepts within configured SLA.

## Socket.IO Event Flow

Connection:

1. Client connects with JWT.
2. Socket middleware verifies token.
3. Socket joins `user:{userId}`, `worker:{workerId}`, or `admin:*` rooms based on role.

Events:

```text
issue.created          backend -> worker rooms
worker.requested       backend -> worker rooms
quote.created          backend -> user room
booking.created        backend -> user and worker rooms
booking.status_changed backend -> booking room
location.updated       worker -> backend -> booking room
chat.message           user/worker -> backend -> booking room
payment.updated        backend -> user room
emergency.created      backend -> admin emergency room and worker rooms
```

## Payment Flow

1. User starts payment.
2. Backend creates provider order.
3. Client completes payment using Razorpay, UPI, or Stripe.
4. Client sends provider result to backend.
5. Backend verifies signature/server-side payment status.
6. Backend updates payment, booking, wallet ledger, and invoice.
7. Backend emits `payment.updated`.

