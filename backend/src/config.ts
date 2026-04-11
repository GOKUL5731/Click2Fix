import dotenv from 'dotenv';
import path from 'path';

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
  otpMaxAttempts: Number(process.env.OTP_MAX_ATTEMPTS ?? 5),
  aiServiceUrl: process.env.AI_SERVICE_URL ?? 'http://localhost:8001',
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:3000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),

  // OpenAI
  openaiApiKey: process.env.OPENAI_API_KEY ?? '',

  // Twilio SMS
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID ?? '',
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN ?? '',
  twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER ?? '',
  twilioVerifyServiceSid: process.env.TWILIO_VERIFY_SERVICE_SID ?? '',
  twilioEnabled: Boolean((process.env.TWILIO_ACCOUNT_SID ?? '').trim() && (process.env.TWILIO_AUTH_TOKEN ?? '').trim()),

  // File uploads
  uploadDir: process.env.UPLOAD_DIR ?? path.join(process.cwd(), 'uploads'),
  maxFileSizeMb: Number(process.env.MAX_FILE_SIZE_MB ?? 25),

  // Emergency
  emergencyRadiusKm: Number(process.env.EMERGENCY_RADIUS_KM ?? 10),
  emergencyPriceMultiplier: Number(process.env.EMERGENCY_PRICE_MULTIPLIER ?? 1.5),

  // Firebase
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
  firebasePrivateKey,
  firebaseStorageBucket: process.env.FIREBASE_STORAGE_BUCKET ?? '',
  firebaseDatabaseUrl: process.env.FIREBASE_DATABASE_URL ?? '',
  firebaseEnabled: Boolean((process.env.FIREBASE_PROJECT_ID ?? '').trim() && (process.env.FIREBASE_CLIENT_EMAIL ?? '').trim() && firebasePrivateKey)
};
