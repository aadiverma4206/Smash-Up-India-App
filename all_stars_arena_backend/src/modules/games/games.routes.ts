import { Router } from "express";
import {
  getGamesController,
  getGameByIdController,
  createMatchOrderController,
  createGameController,
  requestSlotController,
  getActivityLogsController,
  joinGameController,
  switchTeamController,
  leaveGameController,
  cancelPlayerGameController,
  joinWaitlistController,
  leaveWaitlistController,
  updateGameScoreController,
  getGameVideosController,
  getGameRecordingController,
  stopGameRecordingController,
  extendGameRecordingController,
} from "./games.controller.js";
import {
  authenticateToken,
  requireRole,
} from "../../middlewares/auth.middleware.js";

const router = Router();

router.get("/", getGamesController);
router.get("/:id", getGameByIdController);
router.get("/:id/activity", getActivityLogsController);

router.use(authenticateToken);

router.post("/order", requireRole([1, 2, 3]), createMatchOrderController);
router.post("/:id/order", requireRole([1, 2, 3]), createMatchOrderController);
router.post("/create", requireRole([1, 2, 3]), createGameController);
router.post("/", requireRole([1, 2, 3]), createGameController);
router.post("/:id/request-slot", requireRole([3]), requestSlotController);
router.post("/join", requireRole([3]), joinGameController);
router.post("/:id/join", requireRole([3]), joinGameController);
router.post("/:id/switch-team", requireRole([3]), switchTeamController);
router.post("/:id/leave", requireRole([3]), leaveGameController);
router.post("/:id/cancel", requireRole([3]), cancelPlayerGameController);
router.post("/:id/waitlist", requireRole([3]), joinWaitlistController);
router.delete("/:id/waitlist", requireRole([3]), leaveWaitlistController);
router.post("/:id/score", requireRole([1, 2, 3]), updateGameScoreController);

router.get("/:id/videos", requireRole([1, 2, 3]), getGameVideosController);
router.get(
  "/:id/recording",
  requireRole([1, 2, 3]),
  getGameRecordingController,
);
router.post(
  "/:id/recording/stop",
  requireRole([1, 2]),
  stopGameRecordingController,
);
router.post(
  "/:id/recording/extend",
  requireRole([1, 2]),
  extendGameRecordingController,
);

export default router;
