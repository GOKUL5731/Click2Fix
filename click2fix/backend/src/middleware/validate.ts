import type { RequestHandler } from 'express';
import type { ZodSchema } from 'zod';
import { httpError } from './error';

export function validateBody(schema: ZodSchema): RequestHandler {
  return (req, _res, next) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      next(httpError(400, 'Invalid request body', parsed.error.flatten()));
      return;
    }

    req.body = parsed.data;
    next();
  };
}

export function validateQuery(schema: ZodSchema): RequestHandler {
  return (req, _res, next) => {
    const parsed = schema.safeParse(req.query);
    if (!parsed.success) {
      next(httpError(400, 'Invalid query parameters', parsed.error.flatten()));
      return;
    }

    req.query = parsed.data;
    next();
  };
}

