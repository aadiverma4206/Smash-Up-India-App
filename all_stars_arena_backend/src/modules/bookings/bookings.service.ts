import { dbPool } from "../../config/db.config.js";
import { CourtsService } from "../courts/courts.service.js";
import { sendUserNotification } from "../../services/realtime.service.js";
import { ApiError } from "../../utils/apiResponse.js";

function formatTime12h(timeStr: string): string {
  if (!timeStr) return timeStr;
  const parts = timeStr.trim().split(":");
  let hour = parseInt(parts[0], 10);
  const minute = parts[1] || "00";
  if (isNaN(hour)) return timeStr;
  const ampm = hour >= 12 ? "PM" : "AM";
  hour = hour % 12;
  if (hour === 0) hour = 12;
  return `${hour}:${minute} ${ampm}`;
}

function formatDateDisplay(dateStr: string): string {
  if (!dateStr) return dateStr;
  const clean = dateStr.includes("T") ? dateStr.split("T")[0] : dateStr;
  const parts = clean.trim().split("-");
  if (parts.length === 3) {
    const year = parts[0];
    const monthIdx = parseInt(parts[1], 10) - 1;
    const day = parseInt(parts[2], 10);
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    if (!isNaN(day) && monthIdx >= 0 && monthIdx < 12) {
      return `${day} ${months[monthIdx]} ${year}`;
    }
  }
  return dateStr;
}

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
    const cleanDate = bookingDate.includes("T")
      ? bookingDate.split("T")[0]
      : bookingDate;
    const cleanStart = startTime.length === 5 ? `${startTime}:00` : startTime;
    const cleanEnd = endTime.length === 5 ? `${endTime}:00` : endTime;

    const bookingStart = new Date(`${cleanDate}T${cleanStart}+05:30`);
    const bookingEnd = new Date(`${cleanDate}T${cleanEnd}+05:30`);
    const now = new Date();

    if (isNaN(bookingStart.getTime()) || isNaN(bookingEnd.getTime())) {
      throw new ApiError(400, "Invalid booking date or time format");
    }

    if (bookingStart.getTime() < now.getTime() - 2 * 60 * 1000) {
      throw new ApiError(
        400,
        "Cannot book a court pitch in the past. Selected booking date and time have already passed.",
        "PAST_SLOT_NOT_ALLOWED",
      );
    }

    if (bookingEnd <= bookingStart) {
      throw new ApiError(
        400,
        "Booking end time must be strictly after start time",
      );
    }

    const court = await CourtsService.getCourtById(courtId);
    const courtStatus = (court.status || "").toUpperCase();
    if (courtStatus === "MAINTENANCE" || courtStatus === "BLOCKED") {
      throw new ApiError(
        400,
        `Court ${court.name} is currently in ${courtStatus} status and cannot be booked. Please select an active available court pitch.`,
        "COURT_UNAVAILABLE",
      );
    }
    const overlapCheck = await CourtsService.checkCourtOverlap(
      courtId,
      bookingDate,
      startTime,
      endTime,
    );
    if (overlapCheck.hasOverlap) {
      throw new ApiError(
        409,
        `Court ${court.name} is already booked from ${overlapCheck.conflict?.startTime} to ${overlapCheck.conflict?.endTime} on ${bookingDate}. Overlapping time slots are not permitted on the same court. Please choose another time or switch to another court.`,
        "SLOT_ALREADY_BOOKED",
      );
    }

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

      const displayDate = formatDateDisplay(bookingDate);
      const displayStart = formatTime12h(startTime);
      const displayEnd = formatTime12h(endTime);

      sendUserNotification(userId, {
        title: "⚽ Turf Booking Confirmed",
        message: `Booking for ${court.name} on ${displayDate} (${displayStart} - ${displayEnd}) confirmed!`,
        type: "SUCCESS",
      });

      return booking;
    } catch (err: any) {
      if (
        err.code === "23505" ||
        err.message?.includes("already booked") ||
        err.message?.includes("Overlapping time slots") ||
        err.message?.includes("no_overlapping_confirmed_bookings")
      ) {
        throw new ApiError(
          409,
          err.message ||
            "Selected slot is already booked for this court pitch. Please select another slot or another court.",
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
