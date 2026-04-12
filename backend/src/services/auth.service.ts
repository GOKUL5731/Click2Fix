import bcrypt from 'bcryptjs';
import jwt, { type Secret, type SignOptions } from 'jsonwebtoken';
import { z } from 'zod';
import { config } from '../config';
import { query, redis } from '../database/client';
import type { ActorRole, AuthTokenPayload } from '../models/types';
import { httpError } from '../middleware/error';
import { verifyFirebaseIdToken } from './firebase-auth.service';
import { sendOtpSms, sendTwilioVerifyOtp, checkTwilioVerifyOtp } from './sms.service';

const otpMemoryStore = new Map<string, { otp: string; expiresAt: number; attempts: number }>();

// ── Schemas ──────────────────────────────────────────────────────────

export const registerSchema = z.object({
  role: z.enum(['user', 'worker']).default('user'),
  name: z.string().min(2).max(120).optional(),
  phone: z.string().min(8).max(20),
  email: z.preprocess((val) => (val === '' || val === null || val === undefined ? undefined : val), z.string().email().optional()),
  password: z.string().min(8).optional(),
  category: z.string().max(80).optional(),
  experience: z.number().int().min(0).max(60).optional(),
  skills: z.array(z.string()).optional(),
});

export const loginSchema = z.object({
  role: z.enum(['user', 'worker', 'admin']).default('user'),
  phone: z.string().min(8).max(20).optional(),
  email: z.string().email().optional(),
  password: z.string().optional(),
  deviceId: z.string().max(180).optional()
});

export const verifyOtpSchema = z.object({
  role: z.enum(['user', 'worker']).default('user'),
  phone: z.string().min(8).max(20),
  otp: z.string().length(6),
  deviceId: z.string().max(180).optional()
});

export const requestUploadOtpSchema = z.object({
  phone: z.string().min(8).max(20),
});

export const verifyUploadOtpSchema = z.object({
  phone: z.string().min(8).max(20),
  otp: z.string().length(6),
});

export const firebaseLoginSchema = z.object({
  role: z.enum(['user', 'worker']).default('user'),
  idToken: z.string().min(20),
  phone: z.string().min(8).max(20).optional(),
  name: z.string().min(2).max(120).optional(),
  category: z.string().max(80).optional(),
  experience: z.number().int().min(0).max(60).optional(),
  deviceId: z.string().max(180).optional()
});

type RegisterInput = z.infer<typeof registerSchema>;
type LoginInput = z.infer<typeof loginSchema>;
type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
type FirebaseLoginInput = z.infer<typeof firebaseLoginSchema>;

// ── OTP helpers ──────────────────────────────────────────────────────

function otpKey(role: string, phone: string) {
  return `otp:${role}:${phone}`;
}

function createOtp() {
  if (config.nodeEnv !== 'production') {
    return '123456';
  }
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function storeOtp(role: string, phone: string, otp: string) {
  const key = otpKey(role, phone);
  otpMemoryStore.set(key, { otp, expiresAt: Date.now() + config.otpTtlSeconds * 1000, attempts: 0 });

  try {
    await redis.set(key, otp, 'EX', config.otpTtlSeconds);
  } catch {
    // Local development can run without Redis.
  }
}

async function readOtp(role: string, phone: string) {
  const key = otpKey(role, phone);

  try {
    const value = await redis.get(key);
    if (value) return value;
  } catch {
    // Fall through to memory store.
  }

  const item = otpMemoryStore.get(key);
  if (!item || item.expiresAt < Date.now()) return null;

  // Check attempt limit
  if (item.attempts >= config.otpMaxAttempts) {
    return null;
  }

  return item.otp;
}

async function incrementOtpAttempts(role: string, phone: string) {
  const key = otpKey(role, phone);
  const item = otpMemoryStore.get(key);
  if (item) {
    item.attempts += 1;
  }
}

async function clearOtp(role: string, phone: string) {
  const key = otpKey(role, phone);
  otpMemoryStore.delete(key);
  try {
    await redis.del(key);
  } catch {
    // Ignore cleanup failure.
  }
}

function signToken(payload: AuthTokenPayload) {
  const options: SignOptions = { expiresIn: config.jwtExpiresIn as SignOptions['expiresIn'] };
  return jwt.sign(payload, config.jwtSecret as Secret, options);
}

// ── Auth flows ──────────────────────────────────────────────────────

export async function register(input: RegisterInput) {
  const passwordHash = input.password ? await bcrypt.hash(input.password, 12) : null;

  if (input.role === 'worker') {
    await query(
      `INSERT INTO workers (name, phone, category, experience)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           category = COALESCE(EXCLUDED.category, workers.category),
           experience = EXCLUDED.experience`,
      [input.name ?? 'Worker', input.phone, input.category ?? null, input.experience ?? 0]
    );

    // If skills provided, link to categories
    if (input.skills?.length) {
      const worker = await query<{ id: string }>('SELECT id FROM workers WHERE phone = $1', [input.phone]);
      const workerId = worker.rows[0]?.id;
      if (workerId) {
        for (const skill of input.skills) {
          await query(
            `INSERT INTO worker_skills (worker_id, category_id)
             SELECT $1, id FROM categories WHERE LOWER(name) = LOWER($2) OR LOWER(ai_label) = LOWER($2)
             ON CONFLICT DO NOTHING`,
            [workerId, skill]
          );
        }
      }
    }
  } else {
    await query(
      `INSERT INTO users (name, phone, email, password_hash)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, users.name),
           email = COALESCE(EXCLUDED.email, users.email),
           password_hash = COALESCE(EXCLUDED.password_hash, users.password_hash)`,
      [input.name ?? null, input.phone, input.email ?? null, passwordHash]
    );
  }

  if (config.twilioEnabled && config.twilioVerifyServiceSid) {
    await sendTwilioVerifyOtp(input.phone);
    return { message: 'OTP sent' };
  }

  const otp = createOtp();
  await storeOtp(input.role, input.phone, otp);
  await sendOtpSms(input.phone, otp);

  return {
    message: 'OTP sent',
    devOtp: config.nodeEnv === 'production' ? undefined : otp
  };
}

export async function login(input: LoginInput) {
  if (input.role === 'admin') {
    if (!input.email || !input.password) {
      throw httpError(400, 'Admin login requires email and password');
    }

    const result = await query<{ id: string; email: string; password_hash: string }>(
      'SELECT id, email, password_hash FROM admin_users WHERE email = $1 AND is_active = TRUE',
      [input.email]
    );
    const admin = result.rows[0];
    if (!admin || !(await bcrypt.compare(input.password, admin.password_hash))) {
      throw httpError(401, 'Invalid admin credentials');
    }

    const token = signToken({ sub: admin.id, role: 'admin', email: admin.email, deviceId: input.deviceId });
    return { token, role: 'admin' };
  }

  if (!input.phone) {
    throw httpError(400, 'Phone number is required');
  }

  const table = input.role === 'worker' ? 'workers' : 'users';
  const result = await query<{ id: string }>(`SELECT id FROM ${table} WHERE phone = $1`, [input.phone]);

  if (!result.rows[0]) {
    throw httpError(404, `${input.role} not found. Register first.`);
  }

  if (config.twilioEnabled && config.twilioVerifyServiceSid) {
    await sendTwilioVerifyOtp(input.phone);
    return { message: 'OTP sent' };
  }

  const otp = createOtp();
  await storeOtp(input.role, input.phone, otp);
  await sendOtpSms(input.phone, otp);

  return {
    message: 'OTP sent',
    devOtp: config.nodeEnv === 'production' ? undefined : otp
  };
}

export async function verifyOtp(input: VerifyOtpInput) {
  if (config.twilioEnabled && config.twilioVerifyServiceSid) {
    const result = await checkTwilioVerifyOtp(input.phone, input.otp);
    if (!result.valid) throw httpError(401, 'Invalid or expired OTP');
  } else {
    const expectedOtp = await readOtp(input.role, input.phone);
    if (!expectedOtp || expectedOtp !== input.otp) {
      await incrementOtpAttempts(input.role, input.phone);
      throw httpError(401, 'Invalid or expired OTP');
    }
  }

  const table = input.role === 'worker' ? 'workers' : 'users';
  const result = await query<{ id: string; phone: string }>(`SELECT id, phone FROM ${table} WHERE phone = $1`, [
    input.phone
  ]);
  const account = result.rows[0];

  if (!account) {
    throw httpError(404, `${input.role} not found`);
  }

  await clearOtp(input.role, input.phone);

  const token = signToken({
    sub: account.id,
    role: input.role,
    phone: account.phone,
    deviceId: input.deviceId
  });

  return { token, role: input.role, accountId: account.id };
}

// ── Upload OTP (for image upload verification) ──────────────────────

export async function requestUploadOtp(phone: string) {
  if (config.twilioEnabled && config.twilioVerifyServiceSid) {
    await sendTwilioVerifyOtp(phone);
    return { message: 'Upload verification OTP sent' };
  }

  const otp = createOtp();
  await storeOtp('upload', phone, otp);
  await sendOtpSms(phone, otp);

  return {
    message: 'Upload verification OTP sent',
    devOtp: config.nodeEnv === 'production' ? undefined : otp
  };
}

export async function verifyUploadOtp(phone: string, otp: string) {
  if (config.twilioEnabled && config.twilioVerifyServiceSid) {
    const result = await checkTwilioVerifyOtp(phone, otp);
    if (!result.valid) throw httpError(401, 'Invalid or expired upload OTP');
  } else {
    const expectedOtp = await readOtp('upload', phone);
    if (!expectedOtp || expectedOtp !== otp) {
      await incrementOtpAttempts('upload', phone);
      throw httpError(401, 'Invalid or expired upload OTP');
    }
  }

  await clearOtp('upload', phone);

  // Return a one-time upload token valid for 10 minutes
  const uploadToken = jwt.sign(
    { phone, purpose: 'upload', iat: Math.floor(Date.now() / 1000) },
    config.jwtSecret as Secret,
    { expiresIn: '10m' }
  );

  return { verified: true, uploadToken };
}

// ── Firebase login ──────────────────────────────────────────────────

/** Stable 20-char "phone" for DB unique constraint when user signs in with email/Google only. */
function firebaseSyntheticPhone(uid: string): string {
  const compact = uid.replace(/-/g, '');
  return ('f' + compact).slice(0, 20);
}

export async function firebaseLogin(input: FirebaseLoginInput) {
  const identity = await verifyFirebaseIdToken(input.idToken);
  let phone = (input.phone ?? identity.phone)?.trim();
  if (!phone) {
    if (identity.email) {
      phone = firebaseSyntheticPhone(identity.uid);
    } else {
      throw httpError(
        400,
        'Firebase account must include a verified email or phone number.'
      );
    }
  }

  if (input.role === 'worker') {
    const result = await query<{ id: string; phone: string }>(
      `INSERT INTO workers (name, phone, category, experience)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           category = COALESCE(EXCLUDED.category, workers.category),
           experience = EXCLUDED.experience
       RETURNING id, phone`,
      [input.name ?? identity.name ?? 'Worker', phone, input.category ?? null, input.experience ?? 0]
    );

    const account = result.rows[0];
    const token = signToken({
      sub: account.id,
      role: 'worker',
      phone: account.phone,
      deviceId: input.deviceId,
      firebaseUid: identity.uid
    });

    return { token, role: 'worker', accountId: account.id, firebaseUid: identity.uid };
  }

  const userResult = await query<{ id: string; phone: string; email: string | null }>(
    `INSERT INTO users (name, phone, email, profile_photo)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (phone) DO UPDATE
     SET name = COALESCE(EXCLUDED.name, users.name),
         email = COALESCE(EXCLUDED.email, users.email),
         profile_photo = COALESCE(EXCLUDED.profile_photo, users.profile_photo)
     RETURNING id, phone, email`,
    [input.name ?? identity.name ?? null, phone, identity.email ?? null, identity.picture ?? null]
  );

  const user = userResult.rows[0];
  const token = signToken({
    sub: user.id,
    role: 'user',
    phone: user.phone,
    email: user.email ?? identity.email,
    deviceId: input.deviceId,
    firebaseUid: identity.uid
  });

  return { token, role: 'user', accountId: user.id, firebaseUid: identity.uid };
}

export async function logout() {
  return { message: 'Logged out. Client should discard access and refresh tokens.' };
}
