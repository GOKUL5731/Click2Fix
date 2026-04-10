import { Router } from 'express';
import * as workerController from '../controllers/worker.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody, validateQuery } from '../middleware/validate';
import {
  nearbyWorkerQuerySchema,
  sendQuoteSchema,
  setAvailabilitySchema,
  updateLocationSchema
} from '../services/worker.service';

export const workerRoutes = Router();

workerRoutes.get('/nearby', authenticate, validateQuery(nearbyWorkerQuerySchema), workerController.nearby);
workerRoutes.post('/send-quote', authenticate, requireRole('worker'), validateBody(sendQuoteSchema), workerController.sendQuote);
workerRoutes.post(
  '/update-location',
  authenticate,
  requireRole('worker'),
  validateBody(updateLocationSchema),
  workerController.updateLocation
);
workerRoutes.post(
  '/set-availability',
  authenticate,
  requireRole('worker'),
  validateBody(setAvailabilitySchema),
  workerController.setAvailability
);

