import { Router } from 'express';
import { getMessages, sendMessage } from '../controllers/chat.controller';
import { authenticate } from '../middleware/auth';

export const chatRoutes = Router();

chatRoutes.use(authenticate);

chatRoutes.get('/:bookingId', getMessages);
chatRoutes.post('/send', sendMessage);
