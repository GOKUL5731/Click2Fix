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
  idToken: z.string().min(20).optional(),
  firebaseToken: z.string().min(20).optional(),
  phone: z.string().min(8).max(20).optional(),
  email: z.string().email().optional(),
  name: z.string().min(2).max(120).optional(),
  category: z.string().max(80).optional(),
  experience: z.number().int().min(0).max(60).optional(),
  deviceId: z.string().max(180).optional()
}).refine(data => data.idToken || data.firebaseToken, {
  message: "Either idToken or firebaseToken must be provided"
});

export const checkUserSchema = z.object({
  phone: z.string().min(8).max(20).optional(),
  email: z.string().email().optional(),
}).refine(data => data.phone || data.email, {
  message: "Either phone or email must be provided"
});

export const googleLoginSchema = z.object({
  role: z.enum(['user', 'worker', 'admin']).default('user'),
  email: z.string().email(),
  name: z.string().min(2).max(120).optional(),
  photoUrl: z.string().url().optional(),
  firebaseUid: z.string().min(1),
  deviceId: z.string().max(180).optional()
});

export const forgotPasswordSchema = z.object({
  email: z.string().email(),
});

type RegisterInput = z.infer<typeof registerSchema>;
type LoginInput = z.infer<typeof loginSchema>;
type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
type FirebaseLoginInput = z.infer<typeof firebaseLoginSchema>;
type GoogleLoginInput = z.infer<typeof googleLoginSchema>;

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

export async function checkUser(input: { phone?: string; email?: string }) {
  if (input.phone) {
    const userRes = await query('SELECT id FROM users WHERE phone = $1', [input.phone]);
    if (userRes.rows.length > 0) return { exists: true, role: 'user' };
    
    const workerRes = await query('SELECT id FROM workers WHERE phone = $1', [input.phone]);
    if (workerRes.rows.length > 0) return { exists: true, role: 'worker' };
  }
  
  if (input.email) {
    const userRes = await query('SELECT id FROM users WHERE email = $1', [input.email]);
    if (userRes.rows.length > 0) return { exists: true, role: 'user' };
    
    const workerRes = await query('SELECT id FROM workers WHERE email = $1', [input.email]);
    if (workerRes.rows.length > 0) return { exists: true, role: 'worker' };
  }
  
  return { exists: false };
}

export async function register(input: RegisterInput) {
  if (!input.email) {
    throw httpError(400, 'Email is required for registration');
  }

  // Check if user already exists
  const existingUser = await query('SELECT id FROM users WHERE email = $1', [input.email]);
  if (existingUser.rows.length > 0) {
    throw httpError(409, 'Account already exists');
  }

  const passwordHash = input.password ? await bcrypt.hash(input.password, 12) : null;
  const phone = input.phone || '';
  const language = 'en';
  const isActive = true;

  if (input.role === 'worker') {
    await query(
      `INSERT INTO workers (name, phone, category, experience, email, password_hash)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (email) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           phone = COALESCE(EXCLUDED.phone, workers.phone),
           category = COALESCE(EXCLUDED.category, workers.category),
           experience = EXCLUDED.experience,
           password_hash = COALESCE(EXCLUDED.password_hash, workers.password_hash)`,
      [input.name ?? 'Worker', phone, input.category ?? null, input.experience ?? 0, input.email, passwordHash]
    );

    const workerResult = await query<{id: string; email: string; role: string}>(
      'SELECT id, email, $1::text as role FROM workers WHERE email = $2',
      ['worker', input.email]
    );
    const worker = workerResult.rows[0];
    const token = signToken({ sub: worker.id, role: 'worker', email: worker.email });

    return { token, user: { ...worker, name: input.name } };

  } else {
    await query(
      `INSERT INTO users (name, phone, email, password_hash, role, is_active, language)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [input.name ?? null, phone, input.email, passwordHash, 'user', isActive, language]
    );

    const userResult = await query<{id: string; email: string; role: string}>(
      'SELECT id, email, role FROM users WHERE email = $1',
      [input.email]
    );
    const user = userResult.rows[0];
    const token = signToken({ sub: user.id, role: 'user', email: user.email });

    return { token, user: { ...user, name: input.name } };
  }
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

  if (!input.email || !input.password) {
    throw httpError(400, 'Email and password are required');
  }

  const table = input.role === 'worker' ? 'workers' : 'users';
  const result = await query<{ id: string; email: string; password_hash: string; phone: string; name: string }>(
    `SELECT id, email, password_hash, phone, name FROM ${table} WHERE email = $1`,
    [input.email]
  );
  
  const account = result.rows[0];
  if (!account || !account.password_hash || !(await bcrypt.compare(input.password, account.password_hash))) {
    throw httpError(401, 'Invalid email or password');
  }

  const token = signToken({
    sub: account.id,
    role: input.role,
    phone: account.phone,
    email: account.email,
    deviceId: input.deviceId
  });

  return { 
    token, 
    user: {
      id: account.id,
      email: account.email,
      name: account.name,
      phone: account.phone,
      role: input.role
    }
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
  const tokenToUse = input.firebaseToken || input.idToken;
  if (!tokenToUse) {
    throw httpError(400, 'Firebase token is required');
  }
  const identity = await verifyFirebaseIdToken(tokenToUse);
  const email = (input.email ?? identity.email)?.trim();
  
  if (!email) {
    throw httpError(400, 'Firebase account must include a verified email.');
  }

  if (input.role === 'worker') {
    const result = await query<{ id: string; email: string; name: string }>(
      `INSERT INTO workers (name, email, firebase_uid, profile_image)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           firebase_uid = COALESCE(EXCLUDED.firebase_uid, workers.firebase_uid),
           profile_image = COALESCE(EXCLUDED.profile_image, workers.profile_image)
       RETURNING id, email, name`,
      [input.name ?? identity.name ?? 'Worker', email, identity.uid, identity.picture ?? null]
    );

    const account = result.rows[0];
    const token = signToken({
      sub: account.id,
      role: 'worker',
      email: account.email,
      deviceId: input.deviceId,
      firebaseUid: identity.uid
    });

    return { token, user: { ...account, role: 'worker' } };
  }

  const userResult = await query<{ id: string; email: string; name: string }>(
    `INSERT INTO users (name, email, firebase_uid, profile_image, role)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (email) DO UPDATE
     SET name = COALESCE(EXCLUDED.name, users.name),
         firebase_uid = COALESCE(EXCLUDED.firebase_uid, users.firebase_uid),
         profile_image = COALESCE(EXCLUDED.profile_image, users.profile_image)
     RETURNING id, email, name`,
    [input.name ?? identity.name ?? null, email, identity.uid, identity.picture ?? null, 'user']
  );

  const user = userResult.rows[0];
  const token = signToken({
    sub: user.id,
    role: 'user',
    email: user.email,
    deviceId: input.deviceId,
    firebaseUid: identity.uid
  });

  return { token, user: { ...user, role: 'user' } };
}

export async function logout() {
  return { message: 'Logged out. Client should discard access and refresh tokens.' };
}

export async function googleLogin(input: GoogleLoginInput) {
  if (input.role === 'admin') {
    const result = await query<{ id: string; email: string; name: string }>(
      'SELECT id, email, name FROM admin_users WHERE email = $1 AND is_active = TRUE',
      [input.email]
    );
    let admin = result.rows[0];
    if (!admin) {
      const insertResult = await query<{ id: string; email: string; name: string }>(
        `INSERT INTO admin_users (email, name, password_hash, is_active)
         VALUES ($1, $2, $3, TRUE)
         RETURNING id, email, name`,
        [input.email, input.name ?? 'Admin User', 'google-sso']
      );
      admin = insertResult.rows[0];
    }
    const token = signToken({ sub: admin.id, role: 'admin', email: admin.email, deviceId: input.deviceId });
    return { token, user: { id: admin.id, name: admin.name, email: admin.email, role: 'admin' } };
  }

  const table = input.role === 'worker' ? 'workers' : 'users';
  const result = await query<{ id: string; name: string; email: string }>(
    `INSERT INTO ${table} (name, email, firebase_uid, profile_image, role)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (email) DO UPDATE
     SET name = COALESCE(EXCLUDED.name, ${table}.name),
         firebase_uid = COALESCE(EXCLUDED.firebase_uid, ${table}.firebase_uid),
         profile_image = COALESCE(EXCLUDED.profile_image, ${table}.profile_image)
     RETURNING id, name, email`,
    [input.name ?? (input.role === 'worker' ? 'Worker' : null), input.email, input.firebaseUid, input.photoUrl ?? null, input.role]
  );

  const account = result.rows[0];
  const token = signToken({
    sub: account.id,
    role: input.role,
    email: account.email,
    deviceId: input.deviceId,
    firebaseUid: input.firebaseUid
  });

  return { token, user: { ...account, role: input.role } };
}

export async function forgotPassword(input: { email: string }) {
  const user = await query('SELECT id FROM users WHERE email = $1', [input.email]);
  const worker = await query('SELECT id FROM workers WHERE email = $1', [input.email]);
  
  if (user.rows.length === 0 && worker.rows.length === 0) {
    throw httpError(404, 'No account found');
  }

  // In a real app, send email here. For now, simulate success.
  return { message: 'Password reset email sent' };
}

export async function getMe(userId: string, role: string) {
  const table = role === 'worker' ? 'workers' : 'users';
  const result = await query<{ id: string; email: string; name: string; phone: string; role: string; is_active: boolean; profile_image: string }>(
    `SELECT id, email, name, phone, role, is_active, profile_image FROM ${table} WHERE id = $1`,
    [userId]
  );
  
  const account = result.rows[0];
  if (!account) {
    throw httpError(404, 'User not found');
  }

  return { user: account };
}
