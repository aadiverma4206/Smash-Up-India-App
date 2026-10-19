import { Response } from "express";
import { BookingsService } from "./bookings.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const createBookingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { courtId, bookingDate, startTime, endTime } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");
    if (!courtId || !bookingDate || !startTime || !endTime) {
      throw new ApiError(400, "Missing required booking details");
    }

    const booking = await BookingsService.createBooking(
      userId,
      courtId,
      bookingDate,
      startTime,
      endTime,
    );

    res
      .status(201)
      .json(ApiResponse.success("Court pitch booked successfully", booking));
  },
);

export const getUserBookingsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const bookings = await BookingsService.getUserBookings(userId);
    res
      .status(200)
      .json(ApiResponse.success("User bookings retrieved", bookings));
  },
);

export const cancelBookingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: bookingId } = req.params;
    const { reason } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await BookingsService.cancelBooking(
      userId,
      bookingId,
      reason,
    );
    res
      .status(200)
      .json(ApiResponse.success("Booking cancelled successfully", result));
  },
);
