# Implementation Roadmap

## Phase 1: MVP

Goal: prove the core marketplace loop.

Deliverables:

- User phone login and OTP verification.
- Issue upload by image or text.
- AI category and urgency detection with heuristic fallback.
- Nearby worker search.
- Worker quote submission.
- User worker comparison and booking.
- Live worker location event.
- Admin worker approval queue.

Backend:

- Auth, issue, worker, quotation, booking, and admin routes.
- PostgreSQL schema and Prisma migration.
- Redis OTP and live-location store.
- Socket.IO auth and booking rooms.

AI:

- FastAPI service with deterministic MVP classifiers.
- Model interface ready for EfficientNet, MobileNetV3, XGBoost, and fraud models.

Flutter:

- User app navigation and screen placeholders.
- Worker app navigation and screen placeholders.
- Admin dashboard placeholders.

## Phase 2: Advanced

Goal: increase trust, quality, and real-time experience.

Deliverables:

- Face verification.
- Aadhaar document workflow.
- Price prediction model.
- Fraud detection model.
- Chat and voice-call integration.
- Worker trust score.
- Wallet and payout ledger.
- Review quality controls.

## Phase 3: Production

Goal: production hardening and launch readiness.

Deliverables:

- Admin analytics and fraud tooling.
- Emergency mode escalation.
- Multi-language support for English, Tamil, and Hindi.
- Windows app polish.
- Rural area support with offline-friendly flows.
- Observability, SLOs, alerts, backups, and runbooks.
- Payment reconciliation.
- Security review and penetration testing.

## Folder-by-Folder File Creation Order

1. `database/`
   - `schema.sql`
   - Optional migration tooling.

2. `backend/`
   - `package.json`
   - `tsconfig.json`
   - `.env.example`
   - `src/app.ts`
   - `src/server.ts`
   - `src/database/client.ts`
   - `src/middleware/*`
   - `src/services/*`
   - `src/controllers/*`
   - `src/routes/*`
   - `src/sockets/*`

3. `ai_service/`
   - `requirements.txt`
   - `.env.example`
   - `app/main.py`
   - `app/schemas/*`
   - `app/services/*`
   - `app/api/*`

4. `mobile_app/`
   - `pubspec.yaml`
   - `lib/main.dart`
   - `lib/config/*`
   - `lib/models/*`
   - `lib/services/*`
   - `lib/screens/*`
   - `lib/widgets/*`

5. `worker_app/`
   - Same Flutter structure as `mobile_app`, with worker-specific screens.

6. `admin_panel/`
   - Same Flutter structure as `mobile_app`, with dashboard-specific screens.

7. `deployment/`
   - `docker-compose.yml`
   - Service Dockerfiles.
   - Nginx reverse proxy config.
   - CI workflow template.

8. `docs/`
   - Architecture, wireframes, flows, API contracts, and launch checklist.

## Startup Launch Checklist

- Confirm legal rules for Aadhaar handling and data retention.
- Replace OTP mock with Firebase or Twilio integration.
- Replace payment mock with Razorpay production order and webhook verification.
- Enable HTTPS, HSTS, strict CORS, and WAF.
- Use encrypted object storage and signed URLs.
- Complete admin RBAC.
- Add audit logs for worker approval, payment, refunds, document review, and emergency escalation.
- Add monitoring for booking conversion, worker acceptance SLA, emergency response time, and fraud false positives.
- Add privacy policy, terms, worker consent, and user support process.

