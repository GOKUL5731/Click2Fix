import { Router } from 'express';
import * as workerController from '../controllers/worker.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody, validateQuery } from '../middleware/validate';
import { nearbyWorkerQuerySchema, sendQuoteSchema, updateLocationSchema, setAvailabilitySchema } from '../services/worker.service';
import { upload } from '../middleware/upload';

export const workerRoutes = Router();

workerRoutes.get('/nearby', authenticate, validateQuery(nearbyWorkerQuerySchema), workerController.findNearbyWorkers);
workerRoutes.post('/quote', authenticate, requireRole('worker'), validateBody(sendQuoteSchema), workerController.sendQuote);
workerRoutes.put('/location', authenticate, requireRole('worker'), validateBody(updateLocationSchema), workerController.updateLocation);
workerRoutes.put('/availability', authenticate, requireRole('worker'), validateBody(setAvailabilitySchema), workerController.setAvailability);
workerRoutes.post('/document', authenticate, requireRole('worker'), upload.single('file'), workerController.uploadDocument);
workerRoutes.get('/profile', authenticate, requireRole('worker'), workerController.getProfile);
workerRoutes.get('/quotations/:issueId', authenticate, workerController.getQuotations);
