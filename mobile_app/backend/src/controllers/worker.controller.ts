import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as workerService from '../services/worker.service';
import { saveUploadedFile } from '../services/upload.service';

export const findNearbyWorkers = asyncHandler(async (req: Request, res: Response) => {
  res.json(await workerService.findNearbyWorkers(req.query as never));
});

export const sendQuote = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) throw httpError(401, 'Authentication required');
  res.status(201).json(await workerService.sendQuote(req.auth.sub, req.body));
});

export const updateLocation = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) throw httpError(401, 'Authentication required');
  res.json(await workerService.updateWorkerLocation(req.auth.sub, req.body));
});

export const setAvailability = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) throw httpError(401, 'Authentication required');
  res.json(await workerService.setWorkerAvailability(req.auth.sub, req.body));
});

export const uploadDocument = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) throw httpError(401, 'Authentication required');
  const file = req.file;
  if (!file) throw httpError(400, 'Document file is required');

  const uploaded = saveUploadedFile(file);
  const result = await workerService.uploadWorkerDocument(req.auth.sub, {
    documentType: req.body.documentType ?? 'certificate',
    fileUrl: uploaded.url,
  });
  res.status(201).json(result);
});

export const getProfile = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) throw httpError(401, 'Authentication required');
  const profile = await workerService.getWorkerProfile(req.auth.sub);
  if (!profile) throw httpError(404, 'Worker not found');
  res.json(profile);
});

export const getQuotations = asyncHandler(async (req: Request, res: Response) => {
  res.json(await workerService.getQuotationsForIssue(String(req.params.issueId)));
});
