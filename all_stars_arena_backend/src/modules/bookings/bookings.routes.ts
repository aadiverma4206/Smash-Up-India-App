import { Router } from "express";
import {
  createBookingController,
  getUserBookingsController,
  cancelBookingController,
} from "./bookings.controller.js";
import {
  authenticateToken,
  requireRole,
} from "../../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);
router.use(requireRole([3])); // Exclusively for PLAYER

router.post("/", createBookingController);
router.get("/mine", getUserBookingsController);
router.post("/:id/cancel", cancelBookingController);

export default router;
