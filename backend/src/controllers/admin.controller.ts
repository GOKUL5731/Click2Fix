import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error';
import * as adminService from '../services/admin.service';

export const getDashboard = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getDashboard());
});

export const getPendingWorkers = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getPendingWorkers());
});

export const approveWorker = asyncHandler(async (req: Request, res: Response) => {
  res.json(await adminService.approveWorker(req.body, req.auth?.sub));
});

export const reviewDocument = asyncHandler(async (req: Request, res: Response) => {
  res.json(await adminService.reviewDocument(req.body, req.auth?.sub));
});

export const getSystemActivity = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getSystemActivity());
});

export const getAllBookings = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await adminService.getAllBookings());
});
