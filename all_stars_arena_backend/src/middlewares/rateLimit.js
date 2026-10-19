const isDev = process.env.NODE_ENV !== "production";

export const globalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: isDev ? 10000 : 300,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) =>
    isDev ||
    req.ip === "127.0.0.1" ||
    req.ip === "::1" ||
    req.ip === "::ffff:127.0.0.1",
  message: {
    success: false,
    message: "Too many requests from this IP, please try again later.",
    data: null,
    error: {
      code: "RATE_LIMIT_EXCEEDED",
      details: {},
    },
  },
});

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isDev ? 500 : 20,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) =>
    isDev ||
    req.ip === "127.0.0.1" ||
    req.ip === "::1" ||
    req.ip === "::ffff:127.0.0.1",
  message: {
    success: false,
    message:
      "Too many login or OTP attempts, please try again after 15 minutes.",
    data: null,
    error: {
      code: "AUTH_RATE_LIMIT_EXCEEDED",
      details: {},
    },
  },
});
