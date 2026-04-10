import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { approveWorkerSchema, reviewDocumentSchema } from '../services/admin.service';

export const adminRoutes = Router();

adminRoutes.get('/dashboard', authenticate, requireRole('admin'), adminController.getDashboard);
adminRoutes.get('/pending-workers', authenticate, requireRole('admin'), adminController.getPendingWorkers);
adminRoutes.post('/approve-worker', authenticate, requireRole('admin'), validateBody(approveWorkerSchema), adminController.approveWorker);
adminRoutes.post('/review-document', authenticate, requireRole('admin'), validateBody(reviewDocumentSchema), adminController.reviewDocument);
adminRoutes.get('/activity', authenticate, requireRole('admin'), adminController.getSystemActivity);
adminRoutes.get('/bookings', authenticate, requireRole('admin'), adminController.getAllBookings);
