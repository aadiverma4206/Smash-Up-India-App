import { Response } from "express";
import { WalletService } from "./wallet.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const getWalletController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const wallet = await WalletService.getWallet(userId);
    res
      .status(200)
      .json(ApiResponse.success("Wallet details retrieved", wallet));
  },
);

export const setWalletPinController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { pin } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await WalletService.setWalletPin(userId, pin);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const changeWalletPinController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { oldPin, newPin } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await WalletService.changeWalletPin(userId, oldPin, newPin);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const verifyWalletPinController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { pin } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await WalletService.verifyWalletPin(userId, pin);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const topupOrderController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const { amountRupees } = req.body;
    const idempotencyKey =
      req.body.idempotencyKey ||
      (req.headers["x-idempotency-key"] as string) ||
      `idemp_${userId}_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;

    const order = await WalletService.createTopupOrder(
      userId,
      Number(amountRupees),
      idempotencyKey,
    );

    res
      .status(200)
      .json(ApiResponse.success("Top-up order created successfully", order));
  },
);

export const topupVerifyController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const userEmail = req.user?.email || "";
    const {
      paymentOrderId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
    } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await WalletService.verifyTopupPayment(
      userId,
      userEmail,
      paymentOrderId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
    );

    res.status(200).json(ApiResponse.success(result.message, result));
  },
);

export const getTransactionsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const limit = Number(req.query.limit) || 50;
    const offset = Number(req.query.offset) || 0;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const history = await WalletService.getTransactions(userId, limit, offset);
    res
      .status(200)
      .json(
        ApiResponse.success("Wallet transactions history retrieved", history),
      );
  },
);

export const webhookController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const rawBody = req.rawBody?.toString("utf8") || JSON.stringify(req.body);
    const signature = req.headers["x-razorpay-signature"] as string;

    const result = await WalletService.processRazorpayWebhook(
      rawBody,
      signature,
      req.body,
    );
    res.status(200).json(ApiResponse.success("Webhook processed", result));
  },
);
