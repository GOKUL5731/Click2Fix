"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendPushToActorSchema = exports.pushPayloadSchema = exports.unregisterDeviceTokenSchema = exports.registerDeviceTokenSchema = void 0;
exports.createUserNotification = createUserNotification;
exports.createWorkerNotification = createWorkerNotification;
exports.registerDeviceToken = registerDeviceToken;
exports.unregisterDeviceToken = unregisterDeviceToken;
exports.sendPushToActor = sendPushToActor;
const zod_1 = require("zod");
const client_1 = require("../database/client");
const admin_1 = require("../firebase/admin");
exports.registerDeviceTokenSchema = zod_1.z.object({
    fcmToken: zod_1.z.string().min(20).max(4096),
    platform: zod_1.z.enum(['android', 'ios', 'web', 'unknown']).default('unknown'),
    appVariant: zod_1.z.enum(['mobile', 'worker', 'admin']).default('mobile')
});
exports.unregisterDeviceTokenSchema = zod_1.z.object({
    fcmToken: zod_1.z.string().min(20).max(4096)
});
exports.pushPayloadSchema = zod_1.z.object({
    title: zod_1.z.string().min(1).max(160),
    message: zod_1.z.string().min(1).max(1000),
    data: zod_1.z.record(zod_1.z.string(), zod_1.z.string()).optional()
});
exports.sendPushToActorSchema = zod_1.z.object({
    actorRole: zod_1.z.enum(['user', 'worker', 'admin']),
    actorId: zod_1.z.string().uuid(),
    title: zod_1.z.string().min(1).max(160),
    message: zod_1.z.string().min(1).max(1000),
    data: zod_1.z.record(zod_1.z.string(), zod_1.z.string()).optional()
});
async function createUserNotification(userId, title, message, channel = 'in_app') {
    const result = await (0, client_1.query)(`INSERT INTO notifications (user_id, title, message, channel)
     VALUES ($1, $2, $3, $4)
     RETURNING *`, [userId, title, message, channel]);
    return result.rows[0];
}
async function createWorkerNotification(workerId, title, message, channel = 'in_app') {
    const result = await (0, client_1.query)(`INSERT INTO notifications (worker_id, title, message, channel)
     VALUES ($1, $2, $3, $4)
     RETURNING *`, [workerId, title, message, channel]);
    return result.rows[0];
}
async function persistInAppNotification(actorRole, actorId, payload) {
    if (actorRole === 'user') {
        await createUserNotification(actorId, payload.title, payload.message, 'push');
        return;
    }
    if (actorRole === 'worker') {
        await createWorkerNotification(actorId, payload.title, payload.message, 'push');
    }
}
async function mirrorNotificationToFirestore(actorRole, actorId, payload) {
    if (!(0, admin_1.isFirebaseConfigured)()) {
        return;
    }
    try {
        const firestore = (0, admin_1.getFirebaseFirestoreClient)();
        await firestore.collection('notifications').add({
            actorRole,
            actorId,
            title: payload.title,
            message: payload.message,
            data: payload.data ?? {},
            createdAt: new Date().toISOString()
        });
    }
    catch (error) {
        if (process.env.NODE_ENV !== 'production') {
            const message = error instanceof Error ? error.message : String(error);
            console.warn(`Failed to mirror notification to Firestore: ${message}`);
        }
    }
}
async function registerDeviceToken(actorId, actorRole, input) {
    const result = await (0, client_1.query)(`INSERT INTO device_tokens (actor_role, actor_id, fcm_token, platform, app_variant, is_active)
     VALUES ($1, $2, $3, $4, $5, TRUE)
     ON CONFLICT (fcm_token) DO UPDATE
     SET actor_role = EXCLUDED.actor_role,
         actor_id = EXCLUDED.actor_id,
         platform = EXCLUDED.platform,
         app_variant = EXCLUDED.app_variant,
         is_active = TRUE,
         updated_at = NOW()
     RETURNING actor_role, actor_id, fcm_token, platform, app_variant, is_active, updated_at`, [actorRole, actorId, input.fcmToken, input.platform, input.appVariant]);
    return result.rows[0];
}
async function unregisterDeviceToken(actorId, actorRole, input) {
    const result = await (0, client_1.query)(`UPDATE device_tokens
     SET is_active = FALSE, updated_at = NOW()
     WHERE actor_role = $1 AND actor_id = $2 AND fcm_token = $3
     RETURNING id`, [actorRole, actorId, input.fcmToken]);
    return { deactivated: (result.rowCount ?? 0) > 0 };
}
async function deactivateInvalidTokens(invalidTokens) {
    if (!invalidTokens.length) {
        return;
    }
    await (0, client_1.query)(`UPDATE device_tokens
     SET is_active = FALSE, updated_at = NOW()
     WHERE fcm_token = ANY($1::text[])`, [invalidTokens]);
}
async function sendPushToActor(actorRole, actorId, payload) {
    await persistInAppNotification(actorRole, actorId, payload);
    await mirrorNotificationToFirestore(actorRole, actorId, payload);
    const tokenResult = await (0, client_1.query)(`SELECT fcm_token
     FROM device_tokens
     WHERE actor_role = $1 AND actor_id = $2 AND is_active = TRUE`, [actorRole, actorId]);
    const tokens = tokenResult.rows.map((row) => row.fcm_token);
    if (!tokens.length) {
        return {
            deliveredCount: 0,
            failedCount: 0,
            tokenCount: 0,
            reason: 'No active device tokens for actor'
        };
    }
    if (!(0, admin_1.isFirebaseConfigured)()) {
        return {
            deliveredCount: 0,
            failedCount: tokens.length,
            tokenCount: tokens.length,
            reason: 'Firebase not configured on backend'
        };
    }
    try {
        const response = await (0, admin_1.getFirebaseMessagingClient)().sendEachForMulticast({
            tokens,
            notification: {
                title: payload.title,
                body: payload.message
            },
            data: payload.data,
            android: { priority: 'high' },
            apns: {
                headers: { 'apns-priority': '10' },
                payload: { aps: { sound: 'default' } }
            }
        });
        const invalidTokens = [];
        response.responses.forEach((entry, index) => {
            if (entry.success) {
                return;
            }
            const code = entry.error?.code ?? '';
            if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
                invalidTokens.push(tokens[index]);
            }
        });
        await deactivateInvalidTokens(invalidTokens);
        return {
            deliveredCount: response.successCount,
            failedCount: response.failureCount,
            tokenCount: tokens.length,
            invalidTokenCount: invalidTokens.length
        };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Push dispatch failed';
        return {
            deliveredCount: 0,
            failedCount: tokens.length,
            tokenCount: tokens.length,
            reason: message
        };
    }
}
