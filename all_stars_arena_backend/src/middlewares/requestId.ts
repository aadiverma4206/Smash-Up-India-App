import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

export const requestId = (req: Request, res: Response, next: NextFunction) => {
  const reqId = (req.headers['x-request-id'] as string) || `req_${crypto.randomUUID()}`;
  res.setHeader('X-Request-ID', reqId);
  (req as any).id = reqId;
  next();
};
