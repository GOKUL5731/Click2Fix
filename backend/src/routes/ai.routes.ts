import { Router } from 'express';
import * as aiController from '../controllers/ai.controller';
import { authenticate } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { detectIssueSchema, predictPriceSchema } from '../services/ai.service';

export const aiRoutes = Router();

aiRoutes.post('/detect-issue', authenticate, validateBody(detectIssueSchema), aiController.detectIssue);
aiRoutes.post('/predict-price', authenticate, validateBody(predictPriceSchema), aiController.predictPrice);

