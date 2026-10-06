import { dbPool } from '../../config/db.config.js';
import { calculateCourtPrice } from '../../utils/pricing.js';
import { ApiError } from '../../utils/apiResponse.js';

export class CourtsService {
  static async getClubs(city?: string) {
    const query = city
      ? `SELECT * FROM public.clubs WHERE status = 'ACTIVE' AND city = $1 ORDER BY name ASC;`
      : `SELECT * FROM public.clubs WHERE status = 'ACTIVE' ORDER BY name ASC;`;
    const res = await dbPool.query(query, city ? [city] : []);
    return res.rows;
  }

  static async getCourts(clubId?: string) {
    const query = clubId
      ? `SELECT crt.*, clb.name as club_name, clb.city FROM public.courts crt JOIN public.clubs clb ON clb.id = crt.club_id WHERE crt.club_id = $1 AND crt.status = 'AVAILABLE';`
      : `SELECT crt.*, clb.name as club_name, clb.city FROM public.courts crt JOIN public.clubs clb ON clb.id = crt.club_id WHERE crt.status = 'AVAILABLE';`;

    const res = await dbPool.query(query, clubId ? [clubId] : []);
    return res.rows;
  }

  static async getCourtById(courtId: string) {
    const res = await dbPool.query(
      `SELECT crt.*, clb.name as club_name, clb.address, clb.city
       FROM public.courts crt
       JOIN public.clubs clb ON clb.id = crt.club_id
       WHERE crt.id = $1;`,
      [courtId]
    );
    if (res.rows.length === 0) throw new ApiError(404, 'Court pitch not found', 'COURT_NOT_FOUND');
    return res.rows[0];
  }

  static async checkAvailability(courtId: string, bookingDate: string) {
    const bookingsRes = await dbPool.query(
      `SELECT id, start_time, end_time, status
       FROM public.court_bookings
       WHERE court_id = $1 AND booking_date = $2 AND status = 'CONFIRMED';`,
      [courtId, bookingDate]
    );
    return bookingsRes.rows;
  }

  static async calculateQuote(courtId: string, bookingDate: string, startTime: string) {
    const court = await this.getCourtById(courtId);
    const dateObj = new Date(bookingDate);
    const dayOfWeek = dateObj.getDay();
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

    const startHour = Number(startTime.split(':')[0]);
    const isPeak = startHour >= 17 && startHour < 21;

    const baseAmount = calculateCourtPrice(
      court.base_price,
      isWeekend,
      isPeak,
      court.peak_multiplier,
      court.weekend_multiplier
    );

    const gstAmount = Math.round(baseAmount * 0.18 * 100) / 100; // 18% GST
    const platformFee = 50.0; // ₹50 platform fee
    const totalAmount = Math.round((baseAmount + gstAmount + platformFee) * 100) / 100;

    return {
      courtId,
      bookingDate,
      startTime,
      baseAmount,
      isWeekend,
      isPeak,
      gstAmount,
      platformFee,
      totalAmount,
    };
  }
}
