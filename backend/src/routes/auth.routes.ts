import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';
import { otpLimiter } from '../middleware/rateLimit';
import { validateBody } from '../middleware/validate';
import { firebaseLoginSchema, loginSchema, registerSchema, verifyOtpSchema, requestUploadOtpSchema, verifyUploadOtpSchema, googleLoginSchema, checkUserSchema } from '../services/auth.service';

export const authRoutes = Router();

authRoutes.post('/check-user', validateBody(checkUserSchema), authController.checkUser);
authRoutes.post('/register', otpLimiter, validateBody(registerSchema), authController.register);
authRoutes.post('/login', otpLimiter, validateBody(loginSchema), authController.login);
authRoutes.post('/google-login', validateBody(googleLoginSchema), authController.googleLogin);
authRoutes.post('/verify-otp', otpLimiter, validateBody(verifyOtpSchema), authController.verifyOtp);
authRoutes.post('/firebase-login', validateBody(firebaseLoginSchema), authController.firebaseLogin);
authRoutes.post('/request-upload-otp', authenticate, otpLimiter, validateBody(requestUploadOtpSchema), authController.requestUploadOtp);
authRoutes.post('/verify-upload-otp', authenticate, otpLimiter, validateBody(verifyUploadOtpSchema), authController.verifyUploadOtp);
authRoutes.post('/logout', authenticate, authController.logout);
