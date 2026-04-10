import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';
import { otpLimiter } from '../middleware/rateLimit';
import { validateBody } from '../middleware/validate';
import { loginSchema, registerSchema, verifyOtpSchema } from '../services/auth.service';

export const authRoutes = Router();

authRoutes.post('/register', otpLimiter, validateBody(registerSchema), authController.register);
authRoutes.post('/login', otpLimiter, validateBody(loginSchema), authController.login);
authRoutes.post('/verify-otp', otpLimiter, validateBody(verifyOtpSchema), authController.verifyOtp);
authRoutes.post('/logout', authenticate, authController.logout);

