import { Router } from "express";
import { getLeaderboardController } from "./leaderboard.controller.js";

const router = Router();

router.get("/", getLeaderboardController);

export default router;
