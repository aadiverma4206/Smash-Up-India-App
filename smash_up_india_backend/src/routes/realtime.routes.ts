import { Router } from "express";
import {
  sendRealtimeNotification,
  triggerLiveMatchEvent,
} from "../controllers/realtime.controller.js";
import { validateRequest } from "../middlewares/validate.middleware.js";
import {
  sendRealtimeNotificationSchema,
  triggerLiveMatchEventSchema,
} from "./realtime.schema.js";
import {
  authenticateToken,
  requireRole,
} from "../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);

router.post(
  "/notifications/send",
  requireRole([1]),
  validateRequest(sendRealtimeNotificationSchema),
  sendRealtimeNotification,
);

router.post(
  "/matches/trigger",
  requireRole([1, 2]),
  validateRequest(triggerLiveMatchEventSchema),
  triggerLiveMatchEvent,
);

export default router;
