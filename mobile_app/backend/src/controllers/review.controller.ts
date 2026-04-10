import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as reviewService from '../services/review.service';

export const add = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.status(201).json(await reviewService.addReview(req.auth.sub, req.body));
});

