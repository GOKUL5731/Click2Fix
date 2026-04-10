import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as bookingService from '../services/booking.service';

export const createBooking = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.status(201).json(await bookingService.createBooking(req.auth.sub, req.body));
});

export const history = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub || (req.auth.role !== 'user' && req.auth.role !== 'worker')) {
    throw httpError(401, 'Authentication required');
  }

  res.json(await bookingService.getBookingHistory(req.auth.sub, req.auth.role));
});

export const liveLocation = asyncHandler(async (req: Request, res: Response) => {
  res.json(await bookingService.getLiveLocation(String(req.query.bookingId)));
});

export const complete = asyncHandler(async (req: Request, res: Response) => {
  res.json(await bookingService.completeBooking(req.body));
});

