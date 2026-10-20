import { dbPool } from "../../config/db.config.js";
import { CourtsService } from "../courts/courts.service.js";
import { sendUserNotification } from "../../services/realtime.service.js";
import { ApiError } from "../../utils/apiResponse.js";

export class BookingsService {
  static async createBooking(
    userId: string,
    courtId: string,
    bookingDate: string,
    startTime: string,
    endTime: string,
  ) {
    const quote = await CourtsService.calculateQuote(
      courtId,
      bookingDate,
      startTime,
    );
    const court = await CourtsService.getCourtById(courtId);

    try {
      const res = await dbPool.query(
        `INSERT INTO public.court_bookings
         (court_id, club_id, user_id, booking_date, start_time, end_time, amount_paid, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'CONFIRMED')
         RETURNING *;`,
        [
          courtId,
          court.club_id,
          userId,
          bookingDate,
          startTime,
          endTime,
          quote.totalAmount,
        ],
      );

      const booking = res.rows[0];

      sendUserNotification(userId, {
        title: "⚽ Turf Booking Confirmed",
        message: `Booking for ${court.name} on ${bookingDate} (${startTime} - ${endTime}) confirmed!`,
        type: "SUCCESS",
      });

      return booking;
    } catch (err: any) {
      if (
        err.code === "23505" ||
        err.message?.includes("no_overlapping_confirmed_bookings")
      ) {
        throw new ApiError(
          400,
          "Selected slot is already booked for this court pitch. Please select another slot.",
          "SLOT_ALREADY_BOOKED",
        );
      }
      throw err;
    }
  }

  static async getUserBookings(userId: string) {
    const res = await dbPool.query(
      `SELECT b.*, crt.name as court_name, clb.name as club_name
       FROM public.court_bookings b
       JOIN public.courts crt ON crt.id = b.court_id
       JOIN public.clubs clb ON clb.id = b.club_id
       WHERE b.user_id = $1
       ORDER BY b.booking_date DESC, b.start_time DESC;`,
      [userId],
    );
    return res.rows;
  }

  static async cancelBooking(
    userId: string,
    bookingId: string,
    cancellationReason?: string,
  ) {
    const bookingRes = await dbPool.query(
      `SELECT * FROM public.court_bookings WHERE id = $1 AND user_id = $2;`,
      [bookingId, userId],
    );

    if (bookingRes.rows.length === 0) {
      throw new ApiError(404, "Booking not found", "BOOKING_NOT_FOUND");
    }

    const updateRes = await dbPool.query(
      `UPDATE public.court_bookings
       SET status = 'CANCELLED', cancellation_reason = $1
       WHERE id = $2 RETURNING *;`,
      [cancellationReason || "User cancelled", bookingId],
    );

    const cancelledBooking = updateRes.rows[0];

    sendUserNotification(userId, {
      title: "⚽ Booking Cancelled",
      message: `Booking ${bookingId} cancelled. Refund Tier: ${cancelledBooking.refund_tier}, Refund Amount: ₹${cancelledBooking.refund_amount}`,
      type: "INFO",
    });

    return cancelledBooking;
  }
}
