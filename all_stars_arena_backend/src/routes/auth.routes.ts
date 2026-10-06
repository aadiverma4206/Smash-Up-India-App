import { Router } from 'express';
import {
  registerSendOtpController,
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
  registerFcmTokenController,
  deleteFcmTokenController,
} from '../modules/auth/auth.controller.js';
import { validateRequest } from '../middlewares/validate.middleware.js';
import {
  registerSendOtpSchema,
  registerVerifyOtpSchema,
  registerPlayerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotSendOtpSchema,
  forgotVerifyOtpSchema,
  resetPasswordSchema,
  fcmTokenSchema,
} from '../modules/auth/auth.schema.js';
import { authenticateToken } from '../middlewares/auth.middleware.js';

const router = Router();

// Public Registration Flow
router.post(
  '/register/send-otp',
  validateRequest(registerSendOtpSchema),
  registerSendOtpController
);
router.post(
  '/register/verify',
  validateRequest(registerVerifyOtpSchema),
  registerVerifyOtpController
);
router.post(
  '/register',
  validateRequest(registerPlayerSchema),
  registerPlayerController
);

// Public Login & Refresh Flow
router.post('/login', validateRequest(loginSchema), loginController);
router.post('/refresh', validateRequest(refreshTokenSchema), refreshController);

// Public Forgot Password & Reset Flow
router.post(
  '/forgot/send-otp',
  validateRequest(forgotSendOtpSchema),
  forgotSendOtpController
);
router.post(
  '/forgot/verify',
  validateRequest(forgotVerifyOtpSchema),
  forgotVerifyOtpController
);
router.post(
  '/reset-password',
  validateRequest(resetPasswordSchema),
  resetPasswordController
);

// Authenticated Session & Device Routes
router.use(authenticateToken);

router.get('/me', getMeController);
router.post('/logout', logoutController);
router.post('/logout-all', logoutAllController);
router.get('/sessions', getSessionsController);
router.delete('/sessions/:id', revokeSessionController);

// FCM Device Tokens
router.post('/devices/fcm-token', validateRequest(fcmTokenSchema), registerFcmTokenController);
router.delete('/devices/fcm-token', deleteFcmTokenController);

export default router;
