export class ApiResponse<T = any> {
  success: boolean;
  message: string;
  data: T | null;
  error: {
    code: string;
    details: any;
    requestId?: string;
  } | null;

  constructor(success: boolean, message: string, data: T | null = null, error: any = null) {
    this.success = success;
    this.message = message;
    this.data = data;
    this.error = error;
  }

  static success<T = any>(message: string, data: T = {} as T, meta?: any): ApiResponse<T> {
    const res = new ApiResponse<T>(true, message, data, null);
    if (meta !== undefined) {
      (res as any).meta = meta;
    }
    return res;
  }

  static error(message: string, code = 'INTERNAL_ERROR', details: any = {}): ApiResponse<null> {
    return new ApiResponse<null>(false, message, null, { code, details });
  }
}

export class ApiError extends Error {
  statusCode: number;
  code: string;
  details: any;
  isOperational: boolean;

  constructor(statusCode: number, message: string, code = 'BAD_REQUEST', details: any = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;
    Object.setPrototypeOf(this, ApiError.prototype);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }

  static badRequest(message: string, code = 'BAD_REQUEST', details: any = {}): ApiError {
    return new ApiError(400, message, code, details);
  }

  static unauthorized(message = 'Authentication token required or invalid', code = 'UNAUTHORIZED', details: any = {}): ApiError {
    return new ApiError(401, message, code, details);
  }

  static forbidden(message = 'Access forbidden', code = 'FORBIDDEN', details: any = {}): ApiError {
    return new ApiError(403, message, code, details);
  }

  static notFound(message = 'Resource not found', code = 'NOT_FOUND', details: any = {}): ApiError {
    return new ApiError(404, message, code, details);
  }

  static conflict(message = 'Conflict with existing resource', code = 'CONFLICT', details: any = {}): ApiError {
    return new ApiError(409, message, code, details);
  }

  static unprocessable(message = 'Unprocessable entity', code = 'UNPROCESSABLE_ENTITY', details: any = {}): ApiError {
    return new ApiError(422, message, code, details);
  }

  static tooManyRequests(message = 'Too many requests, please slow down', code = 'RATE_LIMIT_EXCEEDED', details: any = {}): ApiError {
    return new ApiError(429, message, code, details);
  }

  static internal(message = 'Internal server error', code = 'INTERNAL_SERVER_ERROR', details: any = {}): ApiError {
    const err = new ApiError(500, message, code, details);
    err.isOperational = false;
    return err;
  }

  static isApiError(err: unknown): err is ApiError {
    return err instanceof ApiError || (typeof err === 'object' && err !== null && 'statusCode' in err && 'code' in err);
  }
}
