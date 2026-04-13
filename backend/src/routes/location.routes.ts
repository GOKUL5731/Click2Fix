import { Router } from 'express';
import { updateLocation, getBookingLocation } from '../controllers/location.controller';
import { authenticate } from '../middleware/auth';

export const locationRoutes = Router();

locationRoutes.use(authenticate);

locationRoutes.post('/update', updateLocation);
locationRoutes.get('/booking/:bookingId', getBookingLocation);
