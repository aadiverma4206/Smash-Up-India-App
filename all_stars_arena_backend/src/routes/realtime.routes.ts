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

const router = Router();

// Send real-time Socket.IO notification to user or broadcast
router.post('/notifications/send', validateRequest(sendRealtimeNotificationSchema), sendRealtimeNotification);

// Broadcast live match score event
router.post('/matches/trigger', validateRequest(triggerLiveMatchEventSchema), triggerLiveMatchEvent);

export default router;
