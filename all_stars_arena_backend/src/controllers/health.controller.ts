import { Request, Response } from 'express';
import { ApiResponse } from '../utils/apiResponse.js';
import { dbPool } from '../config/db.config.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const checkHealth = asyncHandler(async (_req: Request, res: Response) => {
  let dbStatus = 'disconnected';
  let dbDetails = null;

  try {
    const dbRes = await dbPool.query('SELECT current_database(), current_user, version();');
    dbStatus = 'connected';
    dbDetails = dbRes.rows[0];
  } catch (err: any) {
    dbStatus = 'error: ' + err.message;
  }

  res.status(200).json(
    ApiResponse.success('Server is healthy and running', {
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      database: {
        status: dbStatus,
        details: dbDetails,
      },
    })
  );
});
