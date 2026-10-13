import { Router } from 'express';
import {
  sendRealtimeNotification,
  triggerLiveMatchEvent,
} from '../controllers/realtime.controller.js';
import { validateRequest } from '../middlewares/validate.middleware.js';
import {
  sendRealtimeNotificationSchema,
  triggerLiveMatchEventSchema,
} from './realtime.schema.js';
import { authenticateToken, requireRole } from '../middlewares/auth.middleware.js';

const router = Router();

// Protect all real-time routes with JWT authentication
router.use(authenticateToken);

// Send real-time notification to user or global broadcast (Admin only)
router.post(
  '/notifications/send',
  requireRole([1]),
  validateRequest(sendRealtimeNotificationSchema),
  sendRealtimeNotification
);

// Broadcast live match score event (Admin & Manager)
router.post(
  '/matches/trigger',
  requireRole([1, 2]),
  validateRequest(triggerLiveMatchEventSchema),
  triggerLiveMatchEvent
);

export default router;
