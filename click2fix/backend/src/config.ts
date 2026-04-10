import dotenv from 'dotenv';

dotenv.config();

const firebasePrivateKey = (process.env.FIREBASE_PRIVATE_KEY ?? '').replace(/\\n/g, '\n').trim();

export const config = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 8080),
  databaseUrl: process.env.DATABASE_URL ?? 'postgres://postgres:postgres@localhost:5432/click2fix',
  redisUrl: process.env.REDIS_URL ?? 'redis://localhost:6379',
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '1h',
  otpTtlSeconds: Number(process.env.OTP_TTL_SECONDS ?? 300),
  aiServiceUrl: process.env.AI_SERVICE_URL ?? 'http://localhost:8001',
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:3000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
  firebasePrivateKey,
  firebaseStorageBucket: process.env.FIREBASE_STORAGE_BUCKET ?? '',
  firebaseDatabaseUrl: process.env.FIREBASE_DATABASE_URL ?? '',
  firebaseEnabled: Boolean((process.env.FIREBASE_PROJECT_ID ?? '').trim() && (process.env.FIREBASE_CLIENT_EMAIL ?? '').trim() && firebasePrivateKey)
};

