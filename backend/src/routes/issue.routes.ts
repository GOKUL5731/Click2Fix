import { Router } from 'express';
import * as issueController from '../controllers/issue.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { upload } from '../middleware/upload';

export const issueRoutes = Router();

// Create issue with optional file uploads (image, video, voice)
issueRoutes.post(
  '/',
  authenticate,
  requireRole('user'),
  upload.array('files', 4),
  issueController.createIssue
);

issueRoutes.get('/my', authenticate, requireRole('user'), issueController.getUserIssues);
issueRoutes.get('/:id', authenticate, issueController.getIssue);
