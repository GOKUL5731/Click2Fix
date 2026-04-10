import { Router } from 'express';
import * as issueController from '../controllers/issue.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { createIssueSchema } from '../services/issue.service';

export const issueRoutes = Router();

issueRoutes.post('/', authenticate, requireRole('user'), validateBody(createIssueSchema), issueController.createIssue);
issueRoutes.get('/:id', authenticate, issueController.getIssue);

