import { Response } from 'express';
import {
  setUserWalletPin,
  verifyUserWalletPin,
  initiatePaymentOrder,
  verifyAndSettlePayment,
  getWalletHistory,
  joinGameWithWallet,
} from '../services/wallet.service.js';
import { ApiResponse, ApiError } from '../utils/apiResponse.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../types/index.js';

export const setWalletPinController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { pin } = req.body;

    if (!userId) throw new ApiError(401, 'Unauthorized');
    if (!pin || pin.length !== 6) throw new ApiError(400, 'PIN must be exactly 6 digits');

    const result = await setUserWalletPin(userId, pin);
    res.status(200).json(ApiResponse.success(result.message));
  }
);

export const verifyWalletPinController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { pin } = req.body;

    if (!userId) throw new ApiError(401, 'Unauthorized');
    if (!pin) throw new ApiError(400, 'PIN is required');

    const isValid = await verifyUserWalletPin(userId, pin);
    if (!isValid) throw new ApiError(400, 'Incorrect wallet PIN', 'INVALID_WALLET_PIN');

    res.status(200).json(ApiResponse.success('Wallet PIN verified'));
  }
);

export const topupInitiateController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { amount, walletPin } = req.body;

    if (!userId) throw new ApiError(401, 'Unauthorized');
    if (!amount) throw new ApiError(400, 'Amount is required');

    const result = await initiatePaymentOrder(userId, Number(amount), walletPin);
    res.status(200).json(ApiResponse.success('Payment order initiated', result));
  }
);

export const topupVerifyController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const userEmail = req.user?.email || '';
    const { paymentOrderId, razorpayPaymentId, razorpayOrderId, razorpaySignature } = req.body;

    if (!userId) throw new ApiError(401, 'Unauthorized');
    if (!paymentOrderId || !razorpayPaymentId || !razorpayOrderId) {
      throw new ApiError(400, 'Missing payment verification details');
    }

    const result = await verifyAndSettlePayment(
      userId,
      userEmail,
      paymentOrderId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature || ''
    );

    res.status(200).json(ApiResponse.success(result.message, result));
  }
);

export const getWalletHistoryController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const limit = Number(req.query.limit) || 20;
    const offset = Number(req.query.offset) || 0;

    if (!userId) throw new ApiError(401, 'Unauthorized');

    const result = await getWalletHistory(userId, limit, offset);
    res.status(200).json(ApiResponse.success('Wallet history retrieved', result));
  }
);

export const joinGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { gameId, position = 'MID', walletPin } = req.body;

    if (!userId) throw new ApiError(401, 'Unauthorized');
    if (!gameId) throw new ApiError(400, 'Game ID is required');

    const result = await joinGameWithWallet(userId, gameId, position, walletPin);
    res.status(200).json(ApiResponse.success('Joined match successfully', result));
  }
);
