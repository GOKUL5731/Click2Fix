"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.firebaseLoginSchema = exports.verifyUploadOtpSchema = exports.requestUploadOtpSchema = exports.verifyOtpSchema = exports.loginSchema = exports.registerSchema = void 0;
exports.register = register;
exports.login = login;
exports.verifyOtp = verifyOtp;
exports.requestUploadOtp = requestUploadOtp;
exports.verifyUploadOtp = verifyUploadOtp;
exports.firebaseLogin = firebaseLogin;
exports.logout = logout;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const zod_1 = require("zod");
const config_1 = require("../config");
const client_1 = require("../database/client");
const error_1 = require("../middleware/error");
const firebase_auth_service_1 = require("./firebase-auth.service");
const sms_service_1 = require("./sms.service");
const otpMemoryStore = new Map();
// ── Schemas ──────────────────────────────────────────────────────────
exports.registerSchema = zod_1.z.object({
    role: zod_1.z.enum(['user', 'worker']).default('user'),
    name: zod_1.z.string().min(2).max(120).optional(),
    phone: zod_1.z.string().min(8).max(20),
    email: zod_1.z.string().email().optional(),
    password: zod_1.z.string().min(8).optional(),
    category: zod_1.z.string().max(80).optional(),
    experience: zod_1.z.number().int().min(0).max(60).optional(),
    skills: zod_1.z.array(zod_1.z.string()).optional(),
});
exports.loginSchema = zod_1.z.object({
    role: zod_1.z.enum(['user', 'worker', 'admin']).default('user'),
    phone: zod_1.z.string().min(8).max(20).optional(),
    email: zod_1.z.string().email().optional(),
    password: zod_1.z.string().optional(),
    deviceId: zod_1.z.string().max(180).optional()
});
exports.verifyOtpSchema = zod_1.z.object({
    role: zod_1.z.enum(['user', 'worker']).default('user'),
    phone: zod_1.z.string().min(8).max(20),
    otp: zod_1.z.string().length(6),
    deviceId: zod_1.z.string().max(180).optional()
});
exports.requestUploadOtpSchema = zod_1.z.object({
    phone: zod_1.z.string().min(8).max(20),
});
exports.verifyUploadOtpSchema = zod_1.z.object({
    phone: zod_1.z.string().min(8).max(20),
    otp: zod_1.z.string().length(6),
});
exports.firebaseLoginSchema = zod_1.z.object({
    role: zod_1.z.enum(['user', 'worker']).default('user'),
    idToken: zod_1.z.string().min(20),
    phone: zod_1.z.string().min(8).max(20).optional(),
    name: zod_1.z.string().min(2).max(120).optional(),
    category: zod_1.z.string().max(80).optional(),
    experience: zod_1.z.number().int().min(0).max(60).optional(),
    deviceId: zod_1.z.string().max(180).optional()
});
// ── OTP helpers ──────────────────────────────────────────────────────
function otpKey(role, phone) {
    return `otp:${role}:${phone}`;
}
function createOtp() {
    if (config_1.config.nodeEnv !== 'production') {
        return '123456';
    }
    return Math.floor(100000 + Math.random() * 900000).toString();
}
async function storeOtp(role, phone, otp) {
    const key = otpKey(role, phone);
    otpMemoryStore.set(key, { otp, expiresAt: Date.now() + config_1.config.otpTtlSeconds * 1000, attempts: 0 });
    try {
        await client_1.redis.set(key, otp, 'EX', config_1.config.otpTtlSeconds);
    }
    catch {
        // Local development can run without Redis.
    }
}
async function readOtp(role, phone) {
    const key = otpKey(role, phone);
    try {
        const value = await client_1.redis.get(key);
        if (value)
            return value;
    }
    catch {
        // Fall through to memory store.
    }
    const item = otpMemoryStore.get(key);
    if (!item || item.expiresAt < Date.now())
        return null;
    // Check attempt limit
    if (item.attempts >= config_1.config.otpMaxAttempts) {
        return null;
    }
    return item.otp;
}
async function incrementOtpAttempts(role, phone) {
    const key = otpKey(role, phone);
    const item = otpMemoryStore.get(key);
    if (item) {
        item.attempts += 1;
    }
}
async function clearOtp(role, phone) {
    const key = otpKey(role, phone);
    otpMemoryStore.delete(key);
    try {
        await client_1.redis.del(key);
    }
    catch {
        // Ignore cleanup failure.
    }
}
function signToken(payload) {
    const options = { expiresIn: config_1.config.jwtExpiresIn };
    return jsonwebtoken_1.default.sign(payload, config_1.config.jwtSecret, options);
}
// ── Auth flows ──────────────────────────────────────────────────────
async function register(input) {
    const passwordHash = input.password ? await bcryptjs_1.default.hash(input.password, 12) : null;
    if (input.role === 'worker') {
        await (0, client_1.query)(`INSERT INTO workers (name, phone, category, experience)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           category = COALESCE(EXCLUDED.category, workers.category),
           experience = EXCLUDED.experience`, [input.name ?? 'Worker', input.phone, input.category ?? null, input.experience ?? 0]);
        // If skills provided, link to categories
        if (input.skills?.length) {
            const worker = await (0, client_1.query)('SELECT id FROM workers WHERE phone = $1', [input.phone]);
            const workerId = worker.rows[0]?.id;
            if (workerId) {
                for (const skill of input.skills) {
                    await (0, client_1.query)(`INSERT INTO worker_skills (worker_id, category_id)
             SELECT $1, id FROM categories WHERE LOWER(name) = LOWER($2) OR LOWER(ai_label) = LOWER($2)
             ON CONFLICT DO NOTHING`, [workerId, skill]);
                }
            }
        }
    }
    else {
        await (0, client_1.query)(`INSERT INTO users (name, phone, email, password_hash)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, users.name),
           email = COALESCE(EXCLUDED.email, users.email),
           password_hash = COALESCE(EXCLUDED.password_hash, users.password_hash)`, [input.name ?? null, input.phone, input.email ?? null, passwordHash]);
    }
    const otp = createOtp();
    await storeOtp(input.role, input.phone, otp);
    // Send OTP via SMS
    await (0, sms_service_1.sendOtpSms)(input.phone, otp);
    return {
        message: 'OTP sent',
        devOtp: config_1.config.nodeEnv === 'production' ? undefined : otp
    };
}
async function login(input) {
    if (input.role === 'admin') {
        if (!input.email || !input.password) {
            throw (0, error_1.httpError)(400, 'Admin login requires email and password');
        }
        const result = await (0, client_1.query)('SELECT id, email, password_hash FROM admin_users WHERE email = $1 AND is_active = TRUE', [input.email]);
        const admin = result.rows[0];
        if (!admin || !(await bcryptjs_1.default.compare(input.password, admin.password_hash))) {
            throw (0, error_1.httpError)(401, 'Invalid admin credentials');
        }
        const token = signToken({ sub: admin.id, role: 'admin', email: admin.email, deviceId: input.deviceId });
        return { token, role: 'admin' };
    }
    if (!input.phone) {
        throw (0, error_1.httpError)(400, 'Phone number is required');
    }
    const table = input.role === 'worker' ? 'workers' : 'users';
    const result = await (0, client_1.query)(`SELECT id FROM ${table} WHERE phone = $1`, [input.phone]);
    if (!result.rows[0]) {
        throw (0, error_1.httpError)(404, `${input.role} not found. Register first.`);
    }
    const otp = createOtp();
    await storeOtp(input.role, input.phone, otp);
    await (0, sms_service_1.sendOtpSms)(input.phone, otp);
    return {
        message: 'OTP sent',
        devOtp: config_1.config.nodeEnv === 'production' ? undefined : otp
    };
}
async function verifyOtp(input) {
    const expectedOtp = await readOtp(input.role, input.phone);
    if (!expectedOtp || expectedOtp !== input.otp) {
        await incrementOtpAttempts(input.role, input.phone);
        throw (0, error_1.httpError)(401, 'Invalid or expired OTP');
    }
    const table = input.role === 'worker' ? 'workers' : 'users';
    const result = await (0, client_1.query)(`SELECT id, phone FROM ${table} WHERE phone = $1`, [
        input.phone
    ]);
    const account = result.rows[0];
    if (!account) {
        throw (0, error_1.httpError)(404, `${input.role} not found`);
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
async function requestUploadOtp(phone) {
    const otp = createOtp();
    await storeOtp('upload', phone, otp);
    await (0, sms_service_1.sendOtpSms)(phone, otp);
    return {
        message: 'Upload verification OTP sent',
        devOtp: config_1.config.nodeEnv === 'production' ? undefined : otp
    };
}
async function verifyUploadOtp(phone, otp) {
    const expectedOtp = await readOtp('upload', phone);
    if (!expectedOtp || expectedOtp !== otp) {
        await incrementOtpAttempts('upload', phone);
        throw (0, error_1.httpError)(401, 'Invalid or expired upload OTP');
    }
    await clearOtp('upload', phone);
    // Return a one-time upload token valid for 10 minutes
    const uploadToken = jsonwebtoken_1.default.sign({ phone, purpose: 'upload', iat: Math.floor(Date.now() / 1000) }, config_1.config.jwtSecret, { expiresIn: '10m' });
    return { verified: true, uploadToken };
}
// ── Firebase login ──────────────────────────────────────────────────
async function firebaseLogin(input) {
    const identity = await (0, firebase_auth_service_1.verifyFirebaseIdToken)(input.idToken);
    const phone = input.phone ?? identity.phone;
    if (!phone) {
        throw (0, error_1.httpError)(400, 'Firebase login requires a phone number.');
    }
    if (input.role === 'worker') {
        const result = await (0, client_1.query)(`INSERT INTO workers (name, phone, category, experience)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (phone) DO UPDATE
       SET name = COALESCE(EXCLUDED.name, workers.name),
           category = COALESCE(EXCLUDED.category, workers.category),
           experience = EXCLUDED.experience
       RETURNING id, phone`, [input.name ?? identity.name ?? 'Worker', phone, input.category ?? null, input.experience ?? 0]);
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
    const userResult = await (0, client_1.query)(`INSERT INTO users (name, phone, email, profile_photo)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (phone) DO UPDATE
     SET name = COALESCE(EXCLUDED.name, users.name),
         email = COALESCE(EXCLUDED.email, users.email),
         profile_photo = COALESCE(EXCLUDED.profile_photo, users.profile_photo)
     RETURNING id, phone, email`, [input.name ?? identity.name ?? null, phone, identity.email ?? null, identity.picture ?? null]);
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
async function logout() {
    return { message: 'Logged out. Client should discard access and refresh tokens.' };
}
