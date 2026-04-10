import { Router } from 'express';
import * as paymentController from '../controllers/payment.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { paySchema, verifyPaymentSchema } from '../services/payment.service';

export const paymentRoutes = Router();

paymentRoutes.post('/pay', authenticate, requireRole('user'), validateBody(paySchema), paymentController.pay);
paymentRoutes.post('/verify', authenticate, requireRole('user'), validateBody(verifyPaymentSchema), paymentController.verify);

