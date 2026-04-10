import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as notificationService from '../services/notification.service';

export const registerToken = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.status(201).json(await notificationService.registerDeviceToken(req.auth.sub, req.auth.role, req.body));
});

export const unregisterToken = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.json(await notificationService.unregisterDeviceToken(req.auth.sub, req.auth.role, req.body));
});

export const sendTestToSelf = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  const payload = notificationService.pushPayloadSchema.parse(req.body);
  res.json(await notificationService.sendPushToActor(req.auth.role, req.auth.sub, payload));
});

export const sendToActor = asyncHandler(async (req: Request, res: Response) => {
  const payload = notificationService.sendPushToActorSchema.parse(req.body);
  res.json(
    await notificationService.sendPushToActor(payload.actorRole, payload.actorId, {
      title: payload.title,
      message: payload.message,
      data: payload.data
    })
  );
});
