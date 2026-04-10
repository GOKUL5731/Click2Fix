# Database

Apply the schema:

```bash
psql -d click2fix -f schema.sql
psql -d click2fix -f seed.sql
```

Notes:

- `aadhaar_number` should hold an encrypted or tokenized value in production.
- Use PostGIS for production geospatial matching if available.
- Redis should store OTP challenges, live worker locations, and Socket.IO adapter state.
- Payment provider responses are kept in `payments.raw_response` for reconciliation, with sensitive values redacted.

