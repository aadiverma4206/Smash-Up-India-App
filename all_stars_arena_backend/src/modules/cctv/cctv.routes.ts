import { Router } from "express";
import {
  addCamera,
  editCamera,
  toggleCamera,
  testCameraConnection,
  getClubCameras,
  startRecording,
  stopRecording,
  extendRecording,
  getPlaybackUrl,
  getGameRecording,
  getRecordingFailures,
  getFfmpegHealth,
  getLiveCameras,
  createLiveSession,
  getLiveChannelStatus,
  releaseLiveSession,
} from "./cctv.controller.js";
import { validateRequest } from "../../middlewares/validate.middleware.js";
import {
  createCctvCameraSchema,
  updateCctvCameraSchema,
  toggleCameraSchema,
  testCameraSchema,
  startRecordingSchema,
  stopRecordingSchema,
  extendRecordingSchema,
  getPlaybackUrlSchema,
  createLiveStreamSessionSchema,
  getLiveCameraStatusSchema,
} from "./cctv.schema.js";
import {
  authenticateToken,
  requireRole,
} from "../../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);

// Health & Capability Check
router.get("/health", getFfmpegHealth);

// Live CCTV Streaming Routes (Authorized Admin & Manager Only: Roles 1 & 2)
router.get("/live/cameras", requireRole([1, 2]), getLiveCameras);

router.post(
  "/live/session",
  requireRole([1, 2]),
  validateRequest(createLiveStreamSessionSchema),
  createLiveSession,
);

router.get(
  "/live/status/:channel",
  requireRole([1, 2]),
  validateRequest(getLiveCameraStatusSchema),
  getLiveChannelStatus,
);

router.post(
  "/live/session/:sessionId/release",
  requireRole([1, 2]),
  releaseLiveSession,
);

// Manager & Admin CCTV Camera Management Routes (Role 1=ADMIN, Role 2=MANAGER)
router.post(
  "/cameras",
  requireRole([1, 2]),
  validateRequest(createCctvCameraSchema),
  addCamera,
);

router.patch(
  "/cameras/:cameraId",
  requireRole([1, 2]),
  validateRequest(updateCctvCameraSchema),
  editCamera,
);

router.post(
  "/cameras/:cameraId/toggle",
  requireRole([1, 2]),
  validateRequest(toggleCameraSchema),
  toggleCamera,
);

router.post(
  "/cameras/:cameraId/test",
  requireRole([1, 2]),
  validateRequest(testCameraSchema),
  testCameraConnection,
);

router.get("/cameras", requireRole([1, 2]), getClubCameras);
router.get("/clubs/:clubId/cameras", requireRole([1, 2]), getClubCameras);

// CCTV Recording Controls
router.post(
  "/recordings/start",
  requireRole([1, 2]),
  validateRequest(startRecordingSchema),
  startRecording,
);

router.post(
  "/recordings/:recordingId/stop",
  requireRole([1, 2]),
  validateRequest(stopRecordingSchema),
  stopRecording,
);

router.post(
  "/recordings/:recordingId/extend",
  requireRole([1, 2]),
  validateRequest(extendRecordingSchema),
  extendRecording,
);

router.get(
  "/recordings/game/:gameId",
  requireRole([1, 2, 3]),
  getGameRecording,
);

// Monitoring / Failure Diagnostics for Admin & Managers
router.get("/failures", requireRole([1, 2]), getRecordingFailures);

// Player/Manager/Admin Match Video Playback (Both GET and POST supported)
router.get(
  "/playback/:gameId",
  requireRole([1, 2, 3]),
  validateRequest(getPlaybackUrlSchema),
  getPlaybackUrl,
);

router.post(
  "/playback/:gameId",
  requireRole([1, 2, 3]),
  validateRequest(getPlaybackUrlSchema),
  getPlaybackUrl,
);

export default router;
