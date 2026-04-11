import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as aiService from '../services/ai.service';

export const detectIssue = asyncHandler(async (req: Request, res: Response) => {
  res.json(await aiService.detectIssue(req.body));
});

export const predictPrice = asyncHandler(async (req: Request, res: Response) => {
  res.json(await aiService.predictPrice(req.body));
});

/** Analyze an image by URL (no file upload) */
export const analyzeImage = asyncHandler(async (req: Request, res: Response) => {
  const { imageUrl } = req.body as { imageUrl?: string };
  if (!imageUrl) throw httpError(400, 'imageUrl is required');
  res.json(await aiService.analyzeImage(imageUrl));
});

/** Analyze an uploaded image file (multipart/form-data) */
export const analyzeImageFile = asyncHandler(async (req: Request, res: Response) => {
  const file = req.file;
  if (!file) throw httpError(400, 'Image file is required. Send as multipart with field name "file".');

  res.json(
    await aiService.analyzeImageFile(file.buffer, file.mimetype, file.originalname)
  );
});
