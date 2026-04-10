# Production Environment

Installable apps cannot use `localhost` as the API URL. Before sharing APK, AAB, Windows, or iOS builds with other people, deploy the backend and AI service to a public HTTPS domain.

Minimum public environment:

```text
API_BASE_URL=https://api.your-click2fix-domain.com
SOCKET_URL=https://api.your-click2fix-domain.com
```

Backend production requirements:

- PostgreSQL database reachable from backend.
- Redis reachable from backend.
- `JWT_SECRET` set to a long random value.
- Firebase or Twilio OTP configured.
- Razorpay or UPI payment credentials configured.
- Object storage configured for uploads and invoices.
- HTTPS domain and CORS configured for app and admin panel clients.
- Admin user seeded with a hashed password.

Flutter build-time values:

```bash
--dart-define=API_BASE_URL=https://api.your-click2fix-domain.com
--dart-define=SOCKET_URL=https://api.your-click2fix-domain.com
--dart-define=ENVIRONMENT=production
```

Use `release_config.example.json` in each Flutter app folder as the template for real production values.

