import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error';
import * as authService from '../services/auth.service';

export const register = asyncHandler(async (req: Request, res: Response) => {
  res.status(201).json(await authService.register(req.body));
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.login(req.body));
});

export const verifyOtp = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.verifyOtp(req.body));
});

export const firebaseLogin = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.firebaseLogin(req.body));
});

export const requestUploadOtp = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.requestUploadOtp(req.body.phone));
});

export const verifyUploadOtp = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.verifyUploadOtp(req.body.phone, req.body.otp));
});

export const logout = asyncHandler(async (_req: Request, res: Response) => {
  res.json(await authService.logout());
});

export const googleLogin = asyncHandler(async (req: Request, res: Response) => {
  res.json(await authService.googleLogin(req.body));
});
