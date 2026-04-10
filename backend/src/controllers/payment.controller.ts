import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error';
import * as paymentService from '../services/payment.service';

export const pay = asyncHandler(async (req: Request, res: Response) => {
  res.status(201).json(await paymentService.createPayment(req.body));
});

export const verify = asyncHandler(async (req: Request, res: Response) => {
  res.json(await paymentService.verifyPayment(req.body));
});

