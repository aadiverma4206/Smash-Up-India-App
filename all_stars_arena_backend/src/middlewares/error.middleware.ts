import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import multer from "multer";
import { ApiError, ApiResponse } from "../utils/apiResponse.js";
import { isDbError, parseDbError } from "../utils/dbErrors.js";
import { logger } from "../utils/logger.js";

/**
 * Universal Global Error Handler Middleware
 * Intercepts all operational and programmatic errors, ensures standard JSON response format,
 * logs detailed diagnostics with request IDs, and masks internal secrets in production.
 */
export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction,
) => {
  const requestId =
    (req as any).id ||
    (res.getHeader && res.getHeader("X-Request-ID")) ||
    "unknown";
  const method = req.method;
  const url = req.originalUrl || req.url;
  const userId = (req as any).user?.id || null;

  let statusCode = 500;
  let code = "INTERNAL_SERVER_ERROR";
  let message = "An unexpected internal server error occurred";
  let details: any = {};

  // 1. Explicit ApiError
  if (err instanceof ApiError || ApiError.isApiError(err)) {
    statusCode = err.statusCode || 400;
    code = err.code || "BAD_REQUEST";
    message = err.message || "Request failed";
    details = err.details || {};
  }
  // 2. Zod Validation Errors
  else if (err instanceof ZodError || err.name === "ZodError") {
    statusCode = 400;
    code = "VALIDATION_ERROR";
    message = "Validation Error";
    details = (err.errors || []).map((e: any) => ({
      field: (e.path || []).join("."),
      message: e.message,
    }));
  }
  // 3. Joi Validation Errors
  else if (
    err.isJoi ||
    (err.name === "ValidationError" && Array.isArray(err.details))
  ) {
    statusCode = 400;
    code = "VALIDATION_ERROR";
    message = err.message || "Validation Error";
    details = (err.details || []).map((d: any) => ({
      field: (d.path || []).join("."),
      message: d.message,
    }));
  }
  // 4. Multer Upload Errors
  else if (
    err instanceof multer.MulterError ||
    err.name === "MulterError" ||
    (typeof err.code === "string" && err.code.startsWith("LIMIT_"))
  ) {
    statusCode = 400;
    switch (err.code) {
      case "LIMIT_FILE_SIZE":
        code = "FILE_TOO_LARGE";
        message = "File size exceeds maximum allowed limit (5MB)";
        break;
      case "LIMIT_FILE_COUNT":
        code = "TOO_MANY_FILES";
        message = "Too many files uploaded in request";
        break;
      case "LIMIT_UNEXPECTED_FILE":
        code = "UNEXPECTED_FILE";
        message = `Unexpected file field received: ${err.field || "unknown"}`;
        break;
      case "LIMIT_PART_COUNT":
        code = "TOO_MANY_PARTS";
        message = "Multipart request contains too many parts";
        break;
      case "LIMIT_FIELD_KEY":
        code = "FIELD_KEY_TOO_LONG";
        message = "Form field name exceeds maximum permitted length";
        break;
      case "LIMIT_FIELD_VALUE":
        code = "FIELD_VALUE_TOO_LONG";
        message = "Form field value exceeds maximum permitted length";
        break;
      default:
        code = "FILE_UPLOAD_ERROR";
        message = err.message || "File upload error occurred";
    }
    details = { field: err.field, code: err.code };
  }
  // 5. JSON Syntax Error (Malformed JSON payload from client)
  else if (
    err instanceof SyntaxError &&
    "status" in err &&
    (err as any).status === 400 &&
    "body" in err
  ) {
    statusCode = 400;
    code = "INVALID_JSON_PAYLOAD";
    message = "Malformed JSON in request body";
    details =
      process.env.NODE_ENV === "production" ? {} : { syntaxError: err.message };
  }
  // 6. Payload Too Large (Express 413)
  else if (err.type === "entity.too.large" || err.status === 413) {
    statusCode = 413;
    code = "PAYLOAD_TOO_LARGE";
    message = "Request entity exceeds allowed maximum size limit (10MB)";
    details = { limit: "10MB" };
  }
  // 7. JWT / Authentication Errors
  else if (err.name === "TokenExpiredError") {
    statusCode = 401;
    code = "TOKEN_EXPIRED";
    message = "Authentication token has expired. Please log in again.";
  } else if (err.name === "JsonWebTokenError") {
    statusCode = 401;
    code = "INVALID_TOKEN";
    message = "Invalid authentication token provided.";
  } else if (err.name === "NotBeforeError") {
    statusCode = 401;
    code = "TOKEN_NOT_ACTIVE";
    message = "Authentication token is not active yet.";
  }
  // 8. PostgreSQL Database Errors
  else if (
    isDbError(err) ||
    (err.code &&
      typeof err.code === "string" &&
      /^\d{5}$|^[0-9A-Z]{5}$/.test(err.code))
  ) {
    const parsed = parseDbError(err);
    statusCode = parsed.statusCode;
    code = parsed.code;
    message = parsed.message;
    details = parsed.details || {};
  }
  // 9. Axios / External Service Gateway Errors
  else if (err.isAxiosError || Boolean(err.response)) {
    statusCode = err.response?.status || 502;
    code = "EXTERNAL_SERVICE_ERROR";
    message = `External service call failed: ${err.response?.data?.message || err.message}`;
    details =
      process.env.NODE_ENV === "production"
        ? {}
        : { status: err.response?.status, data: err.response?.data };
  }
  // 10. CORS Policy Errors
  else if (err.message && err.message.toLowerCase().includes("cors")) {
    statusCode = 403;
    code = "CORS_ERROR";
    message = "Cross-Origin Request Blocked by server CORS policy";
  }
  // 11. Generic / Unhandled Server Errors
  else {
    statusCode =
      typeof err.statusCode === "number" &&
      err.statusCode >= 400 &&
      err.statusCode < 600
        ? err.statusCode
        : 500;
    code = err.code || (statusCode === 500 ? "INTERNAL_SERVER_ERROR" : "ERROR");
    message =
      process.env.NODE_ENV === "production" && statusCode === 500
        ? "Internal Server Error"
        : err.message || "Internal Server Error";
    details =
      process.env.NODE_ENV === "production" ? null : { stack: err.stack };
  }

  // Structured Logging with Diagnostics
  if (statusCode >= 500) {
    logger.error(
      {
        requestId,
        method,
        url,
        userId,
        statusCode,
        code,
        err,
      },
      `🚨 [5xx Server Error] ${message}`,
    );
  } else if (code === "TOKEN_EXPIRED") {
    // Normal client auth lifecycle event (token expired, client should refresh or re-login)
    logger.info(
      {
        requestId,
        method,
        url,
        statusCode,
        code,
      },
      `🔑 [Auth] ${message}`,
    );
  } else {
    logger.warn(
      {
        requestId,
        method,
        url,
        userId,
        statusCode,
        code,
        details,
      },
      `⚠️ [${statusCode} Client Error] ${message}`,
    );
  }

  const responsePayload = ApiResponse.error(message, code, details);
  if (requestId && requestId !== "unknown" && responsePayload.error) {
    responsePayload.error.requestId = requestId;
  }

  return res.status(statusCode).json(responsePayload);
};
