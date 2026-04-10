import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as workerService from '../services/worker.service';

export const nearby = asyncHandler(async (req: Request, res: Response) => {
  res.json(await workerService.findNearbyWorkers(req.query as never));
});

export const sendQuote = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.status(201).json(await workerService.sendQuote(req.auth.sub, req.body));
});

export const updateLocation = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.json(await workerService.updateWorkerLocation(req.auth.sub, req.body));
});

export const setAvailability = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.json(await workerService.setWorkerAvailability(req.auth.sub, req.body));
});

