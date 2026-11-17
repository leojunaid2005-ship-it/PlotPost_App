import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import authRoutes from './routes/auth.js';
import listingRoutes from './routes/listings.js';
import messageRoutes from './routes/messages.js';
import notificationRoutes from './routes/notifications.js';
import { errorHandler, notFound } from './middleware/errors.js';

export function createApp() {
  const app = express();
  const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(
    cors({
      origin(origin, callback) {
        if (!origin || allowedOrigins.includes(origin)) {
          callback(null, true);
          return;
        }
        callback(new Error('This origin is not allowed by CORS.'));
      },
    }),
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(
    '/api/auth',
    rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: true }),
    authRoutes,
  );
  app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
  app.use('/api/listings', listingRoutes);
  app.use('/api/messages', messageRoutes);
  app.use('/api/notifications', notificationRoutes);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
