import { Request } from 'express';

export interface UserPayload {
  id: string;
  email: string;
  phone?: string;
  roleId: number;
  adminType?: 'SUPER_ADMIN' | 'OPS_ADMIN' | 'FINANCE_ADMIN' | null;
  isOwner?: boolean;
}

export interface AuthenticatedRequest extends Request {
  user?: UserPayload;
  rawBody?: Buffer;
}
