import { Router } from "express";
import {
  getDashboardController,
  getManagerClubController,
  getManagerCourtsController,
  getCourtSlotsController,
  createCourtController,
  updateCourtPricingController,
  simulatePricingController,
  createGameController,
  updateGameController,
  startGameController,
  completeGameController,
  cancelGameController,
  getManagerBookingsController,
  getPendingRequestsController,
  approveSlotRequestController,
  rejectSlotRequestController,
  getClubMatchesController,
  getClubHistoryController,
  getPendingGamesController,
  approvePlayerGameController,
  rejectPlayerGameController,
  getAllPlayersController,
  getPlayerDetailHistoryController,
  blockPlayerController,
  unblockPlayerController,
  submitMatchScoreController,
  getMatchRecordingController,
  stopMatchRecordingController,
  extendMatchRecordingController,
  getManagerCamerasController,
  getGameDetailsController,
  getManagerProfileController,
  uploadManagerAvatarController,
} from "./manager.controller.js";
import {
  addCamera,
  editCamera,
  testCameraConnection,
} from "../cctv/cctv.controller.js";
import {
  createCctvCameraSchema,
  updateCctvCameraSchema,
  testCameraSchema,
} from "../cctv/cctv.schema.js";
import { uploadAvatarMiddleware } from "../../middlewares/upload.middleware.js";
import { validateRequest } from "../../middlewares/validate.middleware.js";
import {
  createCourtSchema,
  updateCourtPricingSchema,
  simulatePricingSchema,
  createGameSchema,
} from "./manager.schema.js";
import {
  authenticateToken,
  requireRole,
} from "../../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);
router.use(requireRole([1, 2]));

router.get("/dashboard", getDashboardController);
router.get("/club", getManagerClubController);

router.get("/courts", getManagerCourtsController);
router.get("/courts/:courtId/slots", getCourtSlotsController);
router.post(
  "/courts",
  validateRequest(createCourtSchema),
  createCourtController,
);
router.put(
  "/courts/:id/pricing",
  validateRequest(updateCourtPricingSchema),
  updateCourtPricingController,
);
router.post(
  "/pricing/simulate",
  validateRequest(simulatePricingSchema),
  simulatePricingController,
);

router.get("/games/pending", getPendingGamesController);
router.get("/games", getClubMatchesController);
router.get("/games/:id", getGameDetailsController);
router.post("/games", validateRequest(createGameSchema), createGameController);
router.put("/games/:id", updateGameController);
router.post("/games/:id/approve", approvePlayerGameController);
router.post("/games/:id/accept", approvePlayerGameController);
router.post("/games/:id/reject", rejectPlayerGameController);
router.post("/games/:id/start", startGameController);
router.post("/games/:id/complete", completeGameController);
router.post("/games/:id/cancel", cancelGameController);
router.post("/games/:id/score", submitMatchScoreController);

router.get("/cameras", getManagerCamerasController);
router.post("/cameras", validateRequest(createCctvCameraSchema), addCamera);
router.patch(
  "/cameras/:cameraId",
  validateRequest(updateCctvCameraSchema),
  editCamera,
);
router.post(
  "/cameras/:cameraId/test",
  validateRequest(testCameraSchema),
  testCameraConnection,
);

router.get("/games/:id/recording", getMatchRecordingController);
router.post("/games/:id/recording/stop", stopMatchRecordingController);
router.post("/games/:id/recording/extend", extendMatchRecordingController);

router.get("/requests", getPendingRequestsController);
router.post("/requests/:id/approve", approveSlotRequestController);
router.post("/requests/:id/reject", rejectSlotRequestController);

router.get("/matches", getClubMatchesController);
router.get("/history", getClubHistoryController);
router.get("/bookings", getManagerBookingsController);

router.get("/players", getAllPlayersController);
router.get("/players/:id", getPlayerDetailHistoryController);
router.post("/players/:id/block", blockPlayerController);
router.post("/players/:id/unblock", unblockPlayerController);

router.get("/profile", getManagerProfileController);
router.post(
  "/profile/avatar",
  uploadAvatarMiddleware,
  uploadManagerAvatarController,
);

export default router;
