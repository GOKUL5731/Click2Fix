import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error';
import * as adminService from '../services/admin.service';

export const dashboard = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getDashboard());
});

export const pendingWorkers = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getPendingWorkers());
});

export const approveWorker = asyncHandler(async (req: Request, res: Response) => {
  res.json(await adminService.approveWorker(req.body, req.auth?.sub));
});

