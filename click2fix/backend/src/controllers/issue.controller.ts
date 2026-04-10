import type { Request, Response } from 'express';
import { asyncHandler, httpError } from '../middleware/error';
import * as issueService from '../services/issue.service';

export const createIssue = asyncHandler(async (req: Request, res: Response) => {
  if (!req.auth?.sub) {
    throw httpError(401, 'Authentication required');
  }

  res.status(201).json(await issueService.createIssue(req.auth.sub, req.body));
});

export const getIssue = asyncHandler(async (req: Request, res: Response) => {
  const issue = await issueService.getIssue(String(req.params.id));
  if (!issue) {
    throw httpError(404, 'Issue not found');
  }

  res.json(issue);
});
