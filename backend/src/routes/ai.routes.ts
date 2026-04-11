import { Router } from 'express';
import * as aiController from '../controllers/ai.controller';
import { authenticate } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { detectIssueSchema, predictPriceSchema } from '../services/ai.service';
import { upload } from '../middleware/upload';

export const aiRoutes = Router();

aiRoutes.post('/detect-issue', authenticate, validateBody(detectIssueSchema), aiController.detectIssue);
aiRoutes.post('/predict-price', authenticate, validateBody(predictPriceSchema), aiController.predictPrice);
// Analyze an image URL
aiRoutes.post('/analyze-image', aiController.analyzeImage);
// Analyze a multipart image file — used by Flutter upload screen immediately after image pick
aiRoutes.post('/analyze-image-file', upload.single('file'), aiController.analyzeImageFile);
