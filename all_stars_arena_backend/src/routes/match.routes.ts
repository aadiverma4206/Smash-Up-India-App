import { Router } from "express";
import {
  getLiveMatchesController,
  getMatchDetailsController,
  updateScoreController,
  startMatchRecordingController,
  stopMatchRecordingController,
  listRecordedMatchesController,
  getMatchRecordingStatusController,
} from "../controllers/match.controller.js";
import { validateRequest } from "../middlewares/validate.middleware.js";
import {
  getMatchDetailsSchema,
  updateScoreSchema,
  startMatchRecordingSchema,
  stopMatchRecordingSchema,
  getMatchStatusSchema,
} from "./match.schema.js";
import { authenticateToken } from "../middlewares/auth.middleware.js";

const router = Router();

// Match Recording APIs
router.get("/", listRecordedMatchesController);
router.post(
  "/start",
  authenticateToken,
  validateRequest(startMatchRecordingSchema),
  startMatchRecordingController,
);
router.post(
  "/stop",
  authenticateToken,
  validateRequest(stopMatchRecordingSchema),
  stopMatchRecordingController,
);

// Match Status and Live Feed
router.get("/live", getLiveMatchesController);
router.get(
  "/:matchId/recording-status",
  validateRequest(getMatchStatusSchema),
  getMatchRecordingStatusController,
);

// Match Details & Scoreboard
router.get(
  "/:gameId",
  validateRequest(getMatchDetailsSchema),
  getMatchDetailsController,
);
router.post(
  "/:gameId/score",
  authenticateToken,
  validateRequest(updateScoreSchema),
  updateScoreController,
);

export default router;
