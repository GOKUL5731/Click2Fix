import bcrypt from 'bcryptjs';
import jwt, { type Secret, type SignOptions } from 'jsonwebtoken';
import { z } from 'zod';
import { config } from '../config';
import { query, redis } from '../database/client';
import type { ActorRole, AuthTokenPayload } from '../models/types';
import { httpError } from '../middleware/error';

const otpMemoryStore = new Map<string, { otp: string; expiresAt: number }>();

export const registerSchema = z.object({
  role: z.enum(['user', 'worker']).default('user'),
  name: z.string().min(2).max(120).optional(),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(8).optional(),
  category: z.string().max(80).optional(),
  experience: z.number().int().min(0).max(60).optional()
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

type RegisterInput = z.infer<typeof registerSchema>;
type LoginInput = z.infer<typeof loginSchema>;
type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;

function otpKey(role: ActorRole, phone: string) {
  return `otp:${role}:${phone}`;
}

function createOtp() {
  if (config.nodeEnv !== 'production') {
    return '123456';
  }

  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function storeOtp(role: ActorRole, phone: string, otp: string) {
  const key = otpKey(role, phone);
  otpMemoryStore.set(key, { otp, expiresAt: Date.now() + config.otpTtlSeconds * 1000 });

  try {
    await redis.set(key, otp, 'EX', config.otpTtlSeconds);
  } catch {
    // Local development can run without Redis. Production should alert on this.
  }
}

async function readOtp(role: ActorRole, phone: string) {
  const key = otpKey(role, phone);

  try {
    const value = await redis.get(key);
    if (value) return value;
  } catch {
    // Fall through to memory store for local development.
  }

  const item = otpMemoryStore.get(key);
  if (!item || item.expiresAt < Date.now()) return null;
  return item.otp;
}

async function clearOtp(role: ActorRole, phone: string) {
  const key = otpKey(role, phone);
  otpMemoryStore.delete(key);

  try {
    await redis.del(key);
  } catch {
    // Ignore Redis cleanup failure in local development.
  }
}

function signToken(payload: AuthTokenPayload) {
  const options: SignOptions = { expiresIn: config.jwtExpiresIn as SignOptions['expiresIn'] };
  return jwt.sign(payload, config.jwtSecret as Secret, options);
}

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

  const otp = createOtp();
  await storeOtp(input.role, input.phone, otp);

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

  const otp = createOtp();
  await storeOtp(input.role, input.phone, otp);

  return {
    message: 'OTP sent',
    devOtp: config.nodeEnv === 'production' ? undefined : otp
  };
}

export async function verifyOtp(input: VerifyOtpInput) {
  const expectedOtp = await readOtp(input.role, input.phone);
  if (!expectedOtp || expectedOtp !== input.otp) {
    throw httpError(401, 'Invalid or expired OTP');
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

export async function logout() {
  return { message: 'Logged out. Client should discard access and refresh tokens.' };
}
