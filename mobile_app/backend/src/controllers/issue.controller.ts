import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as issueService from '../services/issue.service';
import { saveUploadedFile } from '../services/upload.service';
import { analyzeImageFile, transcribeVoice } from '../services/ai.service';

export const createIssue = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  // Handle file uploads from multipart form
  const files = req.files as Express.Multer.File[] | undefined;
  const body = { ...req.body };

  if (files?.length) {
    for (const file of files) {
      const uploaded = saveUploadedFile(file);
      if (uploaded.category === 'images' && !body.imageUrl) {
        body.imageUrl = uploaded.url;
      } else if (uploaded.category === 'videos' && !body.videoUrl) {
        body.videoUrl = uploaded.url;
      } else if (uploaded.category === 'audio' && !body.voiceUrl) {
        body.voiceUrl = uploaded.url;
        // Transcribe voice to text and merge with description
        try {
          const transcription = await transcribeVoice(file.buffer, file.mimetype, file.originalname);
          if (transcription.text) {
            const existing = body.description ?? '';
            body.description = existing
              ? `${existing}\n\n[Voice Input]: ${transcription.text}`
              : transcription.text;
          }
        } catch {
          // Voice transcription is non-blocking
        }
      }
    }
  }

  // Parse numeric fields from form data
  if (typeof body.latitude === 'string') body.latitude = parseFloat(body.latitude);
  if (typeof body.longitude === 'string') body.longitude = parseFloat(body.longitude);
  if (typeof body.isEmergency === 'string') body.isEmergency = body.isEmergency === 'true';

  res.status(201).json(await issueService.createIssue(req.auth.sub, body));
});

export const getIssue = asyncHandler(async (req: Request, res: Response) => {
  const issue = await issueService.getIssue(String(req.params.id));
  if (!issue) {
    throw httpError(404, 'Issue not found');
  }
  res.json(issue);
});

export const getUserIssues = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }
  res.json(await issueService.getUserIssues(req.auth.sub));
});
