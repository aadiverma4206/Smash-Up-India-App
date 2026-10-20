import express, { Request, Response, NextFunction } from "express";
import helmet from "helmet";
import cors from "cors";
import cookieParser from "cookie-parser";
import rateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";
import path from "path";
import fs from "fs";
import apiRoutes from "./routes/index.js";
import { env } from "./config/env.config.js";
import { errorHandler } from "./middlewares/error.middleware.js";
import { requestId } from "./middlewares/requestId.js";
import { swaggerSpec } from "./config/swagger.js";
import { ApiError, ApiResponse } from "./utils/apiResponse.js";
import { HlsStreamingService } from "./services/hlsStreaming.service.js";
import { createProxyMiddleware } from "http-proxy-middleware";

const app = express();

app.use(requestId);

app.use(helmet({ contentSecurityPolicy: false }));

app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true,
  }),
);

const isDev =
  env.NODE_ENV !== "production" || process.env.NODE_ENV !== "production";

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isDev ? 10000 : 300,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) =>
    isDev ||
    req.ip === "127.0.0.1" ||
    req.ip === "::1" ||
    req.ip === "::ffff:127.0.0.1",
  handler: (req: Request, _res: Response, next: NextFunction) => {
    next(
      ApiError.tooManyRequests(
        "Too many requests from this IP, please try again later.",
        "RATE_LIMIT_EXCEEDED",
        { ip: req.ip },
      ),
    );
  },
});

app.use("/api/", apiLimiter);

app.use(
  express.json({
    limit: "10mb",
    verify: (req: any, _res, buf) => {
      req.rawBody = buf;
    },
  }),
);
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
app.use(cookieParser());

app.get("/", (_req: Request, res: Response) => {
  res.status(200).json(
    ApiResponse.success("ALL STARS ARENA Backend API is running", {
      version: "2.0.0",
      docs: "/api-docs",
      apiPrefix: "/api/v1",
    }),
  );
});

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use("/hls", express.static(HlsStreamingService.getHlsBaseDir()));

app.use(
  ["/cctv-stream", "/cam*"],
  createProxyMiddleware({
    target: "http://127.0.0.1:8888",
    changeOrigin: true,
    pathRewrite: (path) => path.replace(/^\/cctv-stream/, ""),
    on: {
      proxyRes: (proxyRes, req) => {
        const reqUrl = (req as any).originalUrl || req.url || "";
        if (proxyRes.headers.location && reqUrl.startsWith("/cctv-stream")) {
          if (!proxyRes.headers.location.startsWith("/cctv-stream")) {
            proxyRes.headers.location = `/cctv-stream${proxyRes.headers.location}`;
          }
        }
      },
    },
  }),
);

app.use("/api/v1", apiRoutes);
app.use("/api", apiRoutes);

app.use((req: Request, _res: Response, next: NextFunction) => {
  next(
    ApiError.notFound(
      `Endpoint ${req.method} ${req.originalUrl} not found`,
      "ROUTE_NOT_FOUND",
      {
        method: req.method,
        url: req.originalUrl,
      },
    ),
  );
});

app.use(errorHandler);

export default app;
