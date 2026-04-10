import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error';
import * as aiService from '../services/ai.service';

export const detectIssue = asyncHandler(async (req: Request, res: Response) => {
  res.json(await aiService.detectIssue(req.body));
});

export const predictPrice = asyncHandler(async (req: Request, res: Response) => {
  res.json(await aiService.predictPrice(req.body));
});

