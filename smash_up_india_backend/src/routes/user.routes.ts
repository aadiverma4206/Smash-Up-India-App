import { Router } from "express";
import { getUserProfile } from "../controllers/user.controller.js";
import { authenticateToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.get("/profile", authenticateToken, getUserProfile);

export default router;
