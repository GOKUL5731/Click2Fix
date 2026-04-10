import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import { config } from './config';
import { errorHandler, notFoundHandler } from './middleware/error';
import { apiLimiter } from './middleware/rateLimit';
import { routes } from './routes';
import fs from 'fs';

export function createApp() {
  const app = express();

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors({ origin: config.corsOrigins, credentials: true }));
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));
  app.use(apiLimiter);

  // Ensure uploads directory exists and serve it statically
  fs.mkdirSync(config.uploadDir, { recursive: true });
  app.use('/uploads', express.static(config.uploadDir));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'click2fix-backend' });
  });

  app.use('/api', routes);
  app.use('/', routes);
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
