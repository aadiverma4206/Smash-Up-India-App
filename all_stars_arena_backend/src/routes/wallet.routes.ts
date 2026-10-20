import { Router } from "express";
import {
  getWalletController,
  setWalletPinController,
  changeWalletPinController,
  verifyWalletPinController,
  topupOrderController,
  topupVerifyController,
  getTransactionsController,
} from "../modules/wallet/wallet.controller.js";
import { validateRequest } from "../middlewares/validate.middleware.js";
import {
  setWalletPinSchema,
  changeWalletPinSchema,
  verifyWalletPinSchema,
  topupOrderSchema,
  topupVerifySchema,
} from "../modules/wallet/wallet.schema.js";
import {
  authenticateToken,
  requireRole,
} from "../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);
router.use(requireRole([3]));

router.get("/", getWalletController);
router.get("/transactions", getTransactionsController);

router.post(
  "/pin",
  validateRequest(setWalletPinSchema),
  setWalletPinController,
);
router.post(
  "/pin/set",
  validateRequest(setWalletPinSchema),
  setWalletPinController,
);
router.post(
  "/pin/change",
  validateRequest(changeWalletPinSchema),
  changeWalletPinController,
);
router.post(
  "/pin/verify",
  validateRequest(verifyWalletPinSchema),
  verifyWalletPinController,
);

router.post(
  "/topup/order",
  validateRequest(topupOrderSchema),
  topupOrderController,
);
router.post(
  "/topup/verify",
  validateRequest(topupVerifySchema),
  topupVerifyController,
);

export default router;
