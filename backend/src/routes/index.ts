import { Router } from 'express';
import { adminRoutes } from './admin.routes';
import { aiRoutes } from './ai.routes';
import { authRoutes } from './auth.routes';
import { bookingRoutes } from './booking.routes';
import { issueRoutes } from './issue.routes';
import { notificationRoutes } from './notification.routes';
import { paymentRoutes } from './payment.routes';
import { reviewRoutes } from './review.routes';
import { workerRoutes } from './worker.routes';
import { versionRoutes } from './version.routes';

export const routes = Router();

routes.use('/auth', authRoutes);
routes.use('/ai', aiRoutes);
routes.use('/issues', issueRoutes);
routes.use('/worker', workerRoutes);
routes.use('/booking', bookingRoutes);
routes.use('/notifications', notificationRoutes);
routes.use('/payment', paymentRoutes);
routes.use('/review', reviewRoutes);
routes.use('/admin', adminRoutes);
routes.use('/app', versionRoutes);
