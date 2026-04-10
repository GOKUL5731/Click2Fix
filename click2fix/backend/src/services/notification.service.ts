import { z } from 'zod';
import { query } from '../database/client';
import { getFirebaseFirestoreClient, getFirebaseMessagingClient, isFirebaseConfigured } from '../firebase/admin';
import type { ActorRole } from '../models/types';

export const registerDeviceTokenSchema = z.object({
  fcmToken: z.string().min(20).max(4096),
  platform: z.enum(['android', 'ios', 'web', 'unknown']).default('unknown'),
  appVariant: z.enum(['mobile', 'worker', 'admin']).default('mobile')
});

export const unregisterDeviceTokenSchema = z.object({
  fcmToken: z.string().min(20).max(4096)
});

export const pushPayloadSchema = z.object({
  title: z.string().min(1).max(160),
  message: z.string().min(1).max(1000),
  data: z.record(z.string(), z.string()).optional()
});

export const sendPushToActorSchema = z.object({
  actorRole: z.enum(['user', 'worker', 'admin']),
  actorId: z.string().uuid(),
  title: z.string().min(1).max(160),
  message: z.string().min(1).max(1000),
  data: z.record(z.string(), z.string()).optional()
});

type PushPayload = z.infer<typeof pushPayloadSchema>;

export async function createUserNotification(userId: string, title: string, message: string, channel = 'in_app') {
  const result = await query(
    `INSERT INTO notifications (user_id, title, message, channel)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, title, message, channel]
  );
  return result.rows[0];
}

export async function createWorkerNotification(workerId: string, title: string, message: string, channel = 'in_app') {
  const result = await query(
    `INSERT INTO notifications (worker_id, title, message, channel)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [workerId, title, message, channel]
  );
  return result.rows[0];
}

async function persistInAppNotification(actorRole: ActorRole, actorId: string, payload: PushPayload) {
  if (actorRole === 'user') {
    await createUserNotification(actorId, payload.title, payload.message, 'push');
    return;
  }

  if (actorRole === 'worker') {
    await createWorkerNotification(actorId, payload.title, payload.message, 'push');
  }
}

async function mirrorNotificationToFirestore(actorRole: ActorRole, actorId: string, payload: PushPayload) {
  if (!isFirebaseConfigured()) {
    return;
  }

  try {
    const firestore = getFirebaseFirestoreClient();
    await firestore.collection('notifications').add({
      actorRole,
      actorId,
      title: payload.title,
      message: payload.message,
      data: payload.data ?? {},
      createdAt: new Date().toISOString()
    });
  } catch (error) {
    if (process.env.NODE_ENV !== 'production') {
      const message = error instanceof Error ? error.message : String(error);
      console.warn(`Failed to mirror notification to Firestore: ${message}`);
    }
  }
}

export async function registerDeviceToken(
  actorId: string,
  actorRole: ActorRole,
  input: z.infer<typeof registerDeviceTokenSchema>
) {
  const result = await query(
    `INSERT INTO device_tokens (actor_role, actor_id, fcm_token, platform, app_variant, is_active)
     VALUES ($1, $2, $3, $4, $5, TRUE)
     ON CONFLICT (fcm_token) DO UPDATE
     SET actor_role = EXCLUDED.actor_role,
         actor_id = EXCLUDED.actor_id,
         platform = EXCLUDED.platform,
         app_variant = EXCLUDED.app_variant,
         is_active = TRUE,
         updated_at = NOW()
     RETURNING actor_role, actor_id, fcm_token, platform, app_variant, is_active, updated_at`,
    [actorRole, actorId, input.fcmToken, input.platform, input.appVariant]
  );

  return result.rows[0];
}

export async function unregisterDeviceToken(
  actorId: string,
  actorRole: ActorRole,
  input: z.infer<typeof unregisterDeviceTokenSchema>
) {
  const result = await query(
    `UPDATE device_tokens
     SET is_active = FALSE, updated_at = NOW()
     WHERE actor_role = $1 AND actor_id = $2 AND fcm_token = $3
     RETURNING id`,
    [actorRole, actorId, input.fcmToken]
  );

  return { deactivated: (result.rowCount ?? 0) > 0 };
}

async function deactivateInvalidTokens(invalidTokens: string[]) {
  if (!invalidTokens.length) {
    return;
  }

  await query(
    `UPDATE device_tokens
     SET is_active = FALSE, updated_at = NOW()
     WHERE fcm_token = ANY($1::text[])`,
    [invalidTokens]
  );
}

export async function sendPushToActor(actorRole: ActorRole, actorId: string, payload: PushPayload) {
  await persistInAppNotification(actorRole, actorId, payload);
  await mirrorNotificationToFirestore(actorRole, actorId, payload);

  const tokenResult = await query<{ fcm_token: string }>(
    `SELECT fcm_token
     FROM device_tokens
     WHERE actor_role = $1 AND actor_id = $2 AND is_active = TRUE`,
    [actorRole, actorId]
  );

  const tokens = tokenResult.rows.map((row) => row.fcm_token);

  if (!tokens.length) {
    return {
      deliveredCount: 0,
      failedCount: 0,
      tokenCount: 0,
      reason: 'No active device tokens for actor'
    };
  }

  if (!isFirebaseConfigured()) {
    return {
      deliveredCount: 0,
      failedCount: tokens.length,
      tokenCount: tokens.length,
      reason: 'Firebase not configured on backend'
    };
  }

  try {
    const response = await getFirebaseMessagingClient().sendEachForMulticast({
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

    const invalidTokens: string[] = [];
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
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Push dispatch failed';
    return {
      deliveredCount: 0,
      failedCount: tokens.length,
      tokenCount: tokens.length,
      reason: message
    };
  }
}

