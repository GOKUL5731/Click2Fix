import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { approveWorkerSchema } from '../services/admin.service';

export const adminRoutes = Router();

adminRoutes.use(authenticate, requireRole('admin'));
adminRoutes.get('/dashboard', adminController.dashboard);
adminRoutes.get('/workers/pending', adminController.pendingWorkers);
adminRoutes.post('/approve-worker', validateBody(approveWorkerSchema), adminController.approveWorker);

