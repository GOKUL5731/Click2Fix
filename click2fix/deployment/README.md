# Deployment

Local stack:

```bash
cd deployment
docker compose up --build
```

Services:

- Backend: `http://localhost:8080`
- AI service: `http://localhost:8001`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

Production target:

- AWS ECS Fargate or Azure Container Apps for backend and AI containers.
- RDS PostgreSQL or Azure Database for PostgreSQL.
- ElastiCache Redis or Azure Cache for Redis.
- S3 or Azure Blob Storage for uploads and invoices.
- CloudFront or Azure Front Door for admin panel and static assets.
- Secrets Manager or Key Vault for credentials.
- Load balancer with HTTPS and WAF.
- CI/CD pipeline that runs backend TypeScript checks, AI Python compile checks, database migrations, Docker builds, and deployment.

