import { Router } from 'express';
import { z } from 'zod';
import * as bookingController from '../controllers/booking.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody, validateQuery } from '../middleware/validate';
import { completeBookingSchema, createBookingSchema } from '../services/booking.service';

export const bookingRoutes = Router();

const liveLocationQuerySchema = z.object({
  bookingId: z.string().uuid()
});

bookingRoutes.post('/create', authenticate, requireRole('user'), validateBody(createBookingSchema), bookingController.createBooking);
bookingRoutes.get('/history', authenticate, bookingController.history);
bookingRoutes.get('/live-location', authenticate, validateQuery(liveLocationQuerySchema), bookingController.liveLocation);
bookingRoutes.post('/complete', authenticate, validateBody(completeBookingSchema), bookingController.complete);

