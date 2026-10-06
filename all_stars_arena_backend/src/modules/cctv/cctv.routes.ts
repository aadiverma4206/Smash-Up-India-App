import { Router } from 'express';
import {
  addCamera,
  editCamera,
  testCameraConnection,
  getClubCameras,
  startRecording,
  stopRecording,
  extendRecording,
  getPlaybackUrl,
} from './cctv.controller.js';
import { validateRequest } from '../../middlewares/validate.middleware.js';
import {
  createCctvCameraSchema,
  updateCctvCameraSchema,
  testCameraSchema,
  startRecordingSchema,
  stopRecordingSchema,
  extendRecordingSchema,
} from './cctv.schema.js';
import { authenticateToken, requireRole } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(authenticateToken);

// Manager & Admin CCTV Camera Management Routes (Role 1=ADMIN, Role 2=MANAGER)
router.post(
  '/cameras',
  requireRole([1, 2]),
  validateRequest(createCctvCameraSchema),
  addCamera
);

router.patch(
  '/cameras/:cameraId',
  requireRole([1, 2]),
  validateRequest(updateCctvCameraSchema),
  editCamera
);

router.post(
  '/cameras/:cameraId/test',
  requireRole([1, 2]),
  validateRequest(testCameraSchema),
  testCameraConnection
);

router.get('/clubs/:clubId/cameras', requireRole([1, 2]), getClubCameras);

// CCTV Recording Controls
router.post(
  '/recordings/start',
  requireRole([1, 2]),
  validateRequest(startRecordingSchema),
  startRecording
);

router.post(
  '/recordings/:recordingId/stop',
  requireRole([1, 2]),
  validateRequest(stopRecordingSchema),
  stopRecording
);

router.post(
  '/recordings/:recordingId/extend',
  requireRole([1, 2]),
  validateRequest(extendRecordingSchema),
  extendRecording
);

// Player/Manager/Admin Match Video Playback
router.get('/playback/:gameId', requireRole([1, 2, 3]), getPlaybackUrl);

export default router;
