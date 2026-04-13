import { Router } from 'express';
import { createRoom } from '../controllers/call.controller';
import { authenticate } from '../middleware/auth';

export const callRoutes = Router();

callRoutes.use(authenticate);

callRoutes.post('/create-room', createRoom);
