# Click2Fix Product Architecture

## Product Goal

Click2Fix lets a household customer capture a repair problem and immediately find verified nearby workers. The product combines AI triage, marketplace matching, real-time communication, live tracking, online payment, ratings, and admin operations.

## Roles

- User: creates issue, compares workers, books, tracks, chats, pays, reviews, downloads invoice.
- Worker: registers, verifies identity, selects skills, receives requests, quotes, navigates, completes jobs, tracks wallet.
- Admin: verifies workers, monitors emergencies, handles complaints, reviews fraud alerts, manages categories and pricing.
- AI service: detects issue category, urgency, price range, face match risk, and fraud signals.

## Applications

### User App

Targets: Android, iOS, Windows.

Core modules:

- Auth: phone login, OTP, optional email login, JWT session, device binding.
- Identity: face capture and verification status.
- Issue intake: camera, gallery, video, text, voice, GPS location.
- AI result: category, confidence, urgency, price range.
- Marketplace: nearby worker search in 2 km, 5 km, 10 km.
- Booking: quote comparison, confirmation, status timeline.
- Real time: chat, worker location, booking updates.
- Money: Razorpay or UPI payment, payment verification, invoice PDF.
- Trust: review and rating.
- Emergency: instant high-priority nearby worker flow.
- Localization: English, Tamil, Hindi.

### Worker App

Core modules:

- Auth and worker onboarding.
- Aadhaar upload and document review.
- Selfie capture and face verification.
- Skill selection: plumbing, electrical, carpentry, cleaning, painting, appliance repair.
- Service area and working hours.
- Availability toggle.
- Nearby requests and request detail.
- Quote submission.
- Navigation and active booking.
- Earnings and wallet.
- Reviews and trust score.

### Admin Panel

Target: Flutter web.

Core modules:

- Admin login and RBAC.
- Dashboard KPIs.
- User management.
- Worker management.
- Worker verification.
- Document review.
- Fraud detection dashboard.
- Booking and complaint management.
- Emergency monitoring.
- Revenue analytics.
- Pricing and category controls.
- Notification broadcasting.

## Backend Architecture

Runtime: Node.js, Express.js, TypeScript.

Responsibilities:

- Validate and authenticate all app requests.
- Store transactional data in PostgreSQL.
- Use Redis for OTPs, sessions, live locations, request fan-out, and rate-limit counters.
- Store uploaded media in S3-compatible storage.
- Call AI service for detection, price prediction, face match, and fraud scoring.
- Emit Socket.IO events for request dispatch, quotes, tracking, chat, emergencies, and booking status.
- Integrate payments through Razorpay, UPI, and optional Stripe.
- Integrate FCM notifications.

Service boundaries:

- AuthService: OTP, JWT, refresh sessions, device binding.
- UserService: profile and face verification status.
- WorkerService: worker registration, skills, availability, location, search.
- IssueService: issue creation and AI enrichment.
- QuoteService: quote submission and comparison.
- BookingService: booking lifecycle and completion OTP.
- PaymentService: order creation, verification, webhooks.
- ReviewService: reviews and trust score updates.
- AdminService: dashboard, approvals, category and pricing controls.
- NotificationService: FCM, in-app notifications, emergency alerts.
- FraudService: collects fraud signals from backend and AI service.

## AI Service Architecture

Runtime: Python, FastAPI.

Modules:

- Repair type detection: EfficientNet or MobileNetV3 model; MVP fallback uses heuristic labels.
- Urgency detection: rules plus classifier. Gas leak is critical, water leak and electrical short are high, fan repair is medium, painting is low.
- Price prediction: XGBoost regression in production, deterministic market-rate fallback in MVP.
- Fraud detection: Isolation Forest or Random Forest using pricing, face duplication, review patterns, and worker behavior.
- Face verification: DeepFace or FaceNet comparison between Aadhaar image and selfie.

Model serving contract:

- `/ai/detect-issue`: returns category, confidence, urgency, price range, and explanation.
- `/ai/predict-price`: returns price lower bound, upper bound, and model version.
- `/ai/fraud-score`: returns risk score and triggered rules.
- `/ai/verify-face`: returns match status, confidence, and review-needed flag.

## Data Architecture

Primary store: PostgreSQL.

Cache and ephemeral state: Redis.

Object storage:

- Issue images and videos.
- Aadhaar document images.
- Profile photos.
- Generated invoices.

Location data:

- Worker current location lives in Redis for fast real-time tracking.
- Periodic snapshots are written to PostgreSQL for audit and matching history.
- Geospatial search uses PostGIS when available. MVP includes simple Haversine fallback in SQL or service code.

## Real-Time Architecture

Socket.IO channels:

- `worker:{workerId}` for worker-specific request dispatch.
- `user:{userId}` for booking, quote, and payment updates.
- `booking:{bookingId}` for chat, location, and status events.
- `admin:emergencies` for emergency monitoring.

Events:

- `issue.created`
- `worker.requested`
- `quote.created`
- `booking.created`
- `booking.status_changed`
- `location.updated`
- `chat.message`
- `payment.updated`
- `emergency.created`

## Security Architecture

- OTP verification via Firebase or Twilio.
- JWT access tokens and refresh-token rotation.
- Bcrypt password hashing for email/password fallback.
- Device binding and session revocation.
- HTTPS only in production.
- Helmet, CORS allowlist, request size limits, and rate limiting.
- Zod request validation.
- Parameterized SQL through Prisma.
- Secure upload validation by MIME type, extension, size, and malware scanning hook.
- Aadhaar number encrypted at rest or stored as last-four plus tokenized reference.
- Face verification status stored as boolean and audit record, not raw face embeddings unless explicitly required and encrypted.
- Worker blacklist table and admin approval workflow.
- Payment webhooks verified with provider signatures.
- Admin RBAC and audit logs.

## Emergency Mode

Emergency examples:

- Gas leak
- Electrical short circuit
- Major water leakage

Behavior:

- Home screen exposes a large red emergency button.
- Backend marks issue priority as `emergency`.
- Quotation wait can be skipped.
- Nearest available verified workers receive high-priority push and Socket.IO event.
- User sees instant tracking and call/chat shortcuts.
- Admin emergency dashboard receives real-time alert.

## Deployment Architecture

Production target: AWS or Azure.

Suggested AWS layout:

- CloudFront for admin web hosting and static assets.
- S3 for media and invoice storage.
- ECS Fargate or EKS for backend and AI service containers.
- RDS PostgreSQL with read replica for analytics.
- ElastiCache Redis for OTPs, sessions, locations, and Socket.IO adapter.
- Application Load Balancer with HTTPS certificates.
- Secrets Manager for keys.
- CloudWatch logs and alarms.
- WAF for admin and public API.
- Firebase Cloud Messaging for notifications.

CI/CD:

- Lint and test backend.
- Lint and test AI service.
- Run database migrations.
- Build Docker images.
- Push images to registry.
- Deploy backend and AI service.
- Build Flutter web admin and upload to static hosting.

## Future Architecture Hooks

- Voice assistant: add speech-to-text service and multilingual intent detection.
- Tamil mixed speech detection: add language ID plus repair-intent classifier.
- Smart home IoT: add device registry and MQTT ingestion.
- Subscriptions: add plan, entitlement, and recurring billing tables.
- Preventive maintenance: add scheduled inspections and prediction model.
- AR repair guidance: add scene recognition and guided overlay module.
- Drone roof inspection: add media ingestion pipeline and roof damage classifier.

