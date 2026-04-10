import type { AuthTokenPayload } from '../models/types';

declare global {
  namespace Express {
    interface Request {
      auth?: AuthTokenPayload;
    }
  }
}

export {};

