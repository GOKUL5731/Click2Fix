import { Router } from 'express';
import * as reviewController from '../controllers/review.controller';
import { authenticate, requireRole } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { addReviewSchema } from '../services/review.service';

export const reviewRoutes = Router();

reviewRoutes.post('/add', authenticate, requireRole('user'), validateBody(addReviewSchema), reviewController.add);

