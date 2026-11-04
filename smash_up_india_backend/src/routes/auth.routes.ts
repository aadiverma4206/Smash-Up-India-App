import { Router } from "express";
import {
  registerSendOtpController,
  resendOtpController,
  registerVerifyOtpController,
  registerPlayerController,
  loginController,
  refreshController,
  logoutController,
  logoutAllController,
  getSessionsController,
  revokeSessionController,
  forgotSendOtpController,
  forgotVerifyOtpController,
  resetPasswordController,
  getMeController,
  updateProfileController,
  registerFcmTokenController,
  deleteFcmTokenController,
} from "../modules/auth/auth.controller.js";
import { validateRequest } from "../middlewares/validate.middleware.js";
import {
  registerSendOtpSchema,
  resendOtpSchema,
  registerVerifyOtpSchema,
  registerPlayerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotSendOtpSchema,
  forgotVerifyOtpSchema,
  resetPasswordSchema,
  fcmTokenSchema,
} from "../modules/auth/auth.schema.js";
import { authenticateToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.post(
  "/register/send-otp",
  validateRequest(registerSendOtpSchema),
  registerSendOtpController,
);
router.post(
  "/register/resend-otp",
  validateRequest(resendOtpSchema),
  resendOtpController,
);
router.post(
  "/resend-otp",
  validateRequest(resendOtpSchema),
  resendOtpController,
);
router.post(
  "/register/verify",
  validateRequest(registerVerifyOtpSchema),
  registerVerifyOtpController,
);
router.post(
  "/register",
  validateRequest(registerPlayerSchema),
  registerPlayerController,
);

router.post("/login", validateRequest(loginSchema), loginController);
router.post("/refresh", validateRequest(refreshTokenSchema), refreshController);

router.post(
  "/forgot/send-otp",
  validateRequest(forgotSendOtpSchema),
  forgotSendOtpController,
);
router.post(
  "/forgot/verify",
  validateRequest(forgotVerifyOtpSchema),
  forgotVerifyOtpController,
);
router.post(
  "/reset-password",
  validateRequest(resetPasswordSchema),
  resetPasswordController,
);

router.use(authenticateToken);

router.get("/me", getMeController);
router.put("/profile", updateProfileController);
router.patch("/profile", updateProfileController);
router.post("/logout", logoutController);
router.post("/logout-all", logoutAllController);
router.get("/sessions", getSessionsController);
router.delete("/sessions/:id", revokeSessionController);

router.post(
  "/devices/fcm-token",
  validateRequest(fcmTokenSchema),
  registerFcmTokenController,
);
router.delete("/devices/fcm-token", deleteFcmTokenController);

export default router;
