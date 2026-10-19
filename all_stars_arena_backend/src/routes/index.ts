import { Router } from "express";
import healthRoutes from "./health.routes.js";
import authRoutes from "./auth.routes.js";
import userRoutes from "./user.routes.js";
import playerRoutes from "../modules/player/player.routes.js";
import managerRoutes from "../modules/manager/manager.routes.js";
import adminRoutes from "../modules/admin/admin.routes.js";
import walletRoutes from "../modules/wallet/wallet.routes.js";
import gamesRoutes from "../modules/games/games.routes.js";
import courtsRoutes from "../modules/courts/courts.routes.js";
import bookingsRoutes from "../modules/bookings/bookings.routes.js";
import tournamentsRoutes from "../modules/tournaments/tournaments.routes.js";
import communityRoutes from "../modules/community/community.routes.js";
import leaderboardRoutes from "../modules/leaderboard/leaderboard.routes.js";
import notificationsRoutes from "../modules/notifications/notifications.routes.js";
import videosRoutes from "../modules/videos/videos.routes.js";
import matchRoutes from "./match.routes.js";
import realtimeRoutes from "./realtime.routes.js";
import cctvRoutes from "../modules/cctv/cctv.routes.js";
import { webhookController } from "../modules/wallet/wallet.controller.js";

const router = Router();

router.use("/health", healthRoutes);
router.use("/auth", authRoutes);
router.use("/user", userRoutes);
router.use("/player", playerRoutes);
router.use("/manager", managerRoutes);
router.use("/admin", adminRoutes);
router.use("/wallet", walletRoutes);
router.use("/games", gamesRoutes);
router.use("/courts", courtsRoutes);
router.use("/bookings", bookingsRoutes);
router.use("/tournaments", tournamentsRoutes);
router.use("/community", communityRoutes);
router.use("/leaderboard", leaderboardRoutes);
router.use("/notifications", notificationsRoutes);
router.use("/videos", videosRoutes);
router.use("/game-videos", videosRoutes);
router.use("/matches", matchRoutes);
router.use("/realtime", realtimeRoutes);
router.use("/cctv", cctvRoutes);

// Razorpay Webhooks
router.post("/webhooks/razorpay", webhookController);

export default router;
