import rateLimit from 'express-rate-limit';

export const globalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
    data: null,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      details: {},
    },
  },
});

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // Strict limit for auth attempts
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many login or OTP attempts, please try again after 15 minutes.',
    data: null,
    error: {
      code: 'AUTH_RATE_LIMIT_EXCEEDED',
      details: {},
    },
  },
});
