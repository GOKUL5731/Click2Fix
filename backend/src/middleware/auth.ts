import type { NextFunction, Request, RequestHandler, Response } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import type { ActorRole, AuthTokenPayload } from '../models/types';
import { httpError } from './error';

export const authenticate: RequestHandler = (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;

  if (!token) {
    next(httpError(401, 'Missing bearer token'));
    return;
  }

  try {
    req.auth = jwt.verify(token, config.jwtSecret) as AuthTokenPayload;
    next();
  } catch {
    next(httpError(401, 'Invalid or expired token'));
  }
};

export function requireRole(...roles: ActorRole[]): RequestHandler {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.auth) {
      next(httpError(401, 'Authentication required'));
      return;
    }

    if (!roles.includes(req.auth.role)) {
      next(httpError(403, 'Insufficient permissions'));
      return;
    }

    next();
  };
}

