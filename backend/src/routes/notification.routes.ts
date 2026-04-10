import { Router } from 'express';
import * as notificationController from '../controllers/notification.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import {
  pushPayloadSchema,
  registerDeviceTokenSchema,
  sendPushToActorSchema,
  unregisterDeviceTokenSchema
} from '../services/notification.service';

export const notificationRoutes = Router();

notificationRoutes.post(
  '/register-token',
  authenticate,
  validateBody(registerDeviceTokenSchema),
  notificationController.registerToken
);
notificationRoutes.post(
  '/unregister-token',
  authenticate,
  validateBody(unregisterDeviceTokenSchema),
  notificationController.unregisterToken
);
notificationRoutes.post('/send-test', authenticate, validateBody(pushPayloadSchema), notificationController.sendTestToSelf);
notificationRoutes.post(
  '/send',
  authenticate,
  requireRole('admin'),
  validateBody(sendPushToActorSchema),
  notificationController.sendToActor
);
