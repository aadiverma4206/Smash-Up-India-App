import express, { Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import apiRoutes from './routes/index.js';
import { env } from './config/env.config.js';
import { errorHandler } from './middlewares/error.middleware.js';
import { requestId } from './middlewares/requestId.js';
import { swaggerSpec } from './config/swagger.js';
import { ApiError, ApiResponse } from './utils/apiResponse.js';

const app = express();

// Assign unique X-Request-ID header & attach to req.id
app.use(requestId);

// Security Headers via Helmet
app.use(helmet({ contentSecurityPolicy: false }));

// CORS Config
app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true,
  })
);

// Global Rate Limiter (100 requests per 15 minutes per IP)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req: Request, _res: Response, next: NextFunction) => {
    next(
      ApiError.tooManyRequests(
        'Too many requests from this IP, please try again later.',
        'RATE_LIMIT_EXCEEDED',
        { ip: req.ip }
      )
    );
  },
});

app.use('/api/', apiLimiter);

// Body Parsers (with rawBody capture for Razorpay webhooks)
app.use(
  express.json({
    limit: '10mb',
    verify: (req: any, _res, buf) => {
      req.rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// Root endpoint info
app.get('/', (_req: Request, res: Response) => {
  res.status(200).json(
    ApiResponse.success('ALL STARS ARENA Backend API is running', {
      version: '2.0.0',
      docs: '/api-docs',
      apiPrefix: '/api/v1',
    })
  );
});

// Swagger OpenAPI Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// API Master Router
app.use('/api/v1', apiRoutes);

// Catch-all 404 Not Found Handler for unmatched routes
app.use((req: Request, _res: Response, next: NextFunction) => {
  next(
    ApiError.notFound(
      `Endpoint ${req.method} ${req.originalUrl} not found`,
      'ROUTE_NOT_FOUND',
      {
        method: req.method,
        url: req.originalUrl,
      }
    )
  );
});

// Global Universal Error Handler
app.use(errorHandler);

export default app;
