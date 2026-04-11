import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import { config } from './config';
import { errorHandler, notFoundHandler } from './middleware/error';
import { apiLimiter } from './middleware/rateLimit';
import { routes } from './routes';
import { healthCheck } from './database/client';
import fs from 'fs';

export function createApp() {
  const app = express();

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors({
    origin: config.corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));
  app.use(apiLimiter);

  // Keep-Alive to prevent Render cold-start drops
  app.use((_req, res, next) => {
    res.setHeader('Connection', 'keep-alive');
    next();
  });

  // Ensure uploads directory exists and serve it statically
  fs.mkdirSync(config.uploadDir, { recursive: true });
  app.use('/uploads', express.static(config.uploadDir));

  // Health check with DB status for Render startup probe
  app.get('/health', async (_req, res) => {
    try {
      const db = await healthCheck();
      res.json({ status: 'ok', service: 'click2fix-backend', database: db.database, timestamp: new Date().toISOString() });
    } catch (err) {
      res.status(503).json({ status: 'degraded', service: 'click2fix-backend', error: String(err) });
    }
  });

  // All API routes under /api — single clean mount (no double registration)
  app.use('/api', routes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

