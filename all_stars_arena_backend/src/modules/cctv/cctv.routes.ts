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

router.get("/health", getFfmpegHealth);

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

router.get("/failures", requireRole([1, 2]), getRecordingFailures);

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
