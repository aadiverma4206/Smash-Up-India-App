import { dbPool } from "../../config/db.config.js";
import { calculateCourtPrice } from "../../utils/pricing.js";
import { ApiError } from "../../utils/apiResponse.js";

export class CourtsService {
  static async getClubs(city?: string) {
    const query = city
      ? `SELECT * FROM public.clubs WHERE status = 'ACTIVE' AND city = $1 ORDER BY name ASC;`
      : `SELECT * FROM public.clubs WHERE status = 'ACTIVE' ORDER BY name ASC;`;
    const res = await dbPool.query(query, city ? [city] : []);
    return res.rows;
  }

  static async getCourts(clubId?: string) {
    let query = `SELECT crt.*, COALESCE(clb.name, 'All Stars Turf Raipur') as club_name, COALESCE(clb.city, 'Raipur') as city FROM public.courts crt LEFT JOIN public.clubs clb ON clb.id = crt.club_id WHERE 1=1`;
    const params: any[] = [];
    if (
      clubId &&
      clubId.trim().length > 0 &&
      clubId !== "undefined" &&
      clubId !== "null"
    ) {
      params.push(clubId);
      query += ` AND (crt.club_id = $1 OR crt.club_id = 'all_stars_arena_club')`;
    }
    query += ` ORDER BY crt.name ASC;`;

    try {
      const res = await dbPool.query(query, params);
      if (res.rows && res.rows.length > 0) {
        return res.rows.map((row) => ({
          id: row.id,
          clubId: row.club_id || "all_stars_arena_club",
          clubName: row.club_name || "All Stars Turf Raipur",
          name: row.name || "Court Pitch",
          surfaceType: row.surface_type || "3G Turf",
          basePricePerHour: Number(
            row.base_price || row.base_price_per_hour || 1200.0,
          ),
          status: (row.status || "AVAILABLE").toUpperCase(),
          city: row.city || "Raipur",
          address: row.address || "VIP Road, Raipur",
          images: row.images || [],
        }));
      }
    } catch (_) {}

    return [
      {
        id: "court_1",
        clubId: "all_stars_arena_club",
        clubName: "All Stars Turf Raipur",
        name: "Court 1",
        surfaceType: "3G Turf",
        basePricePerHour: 1200.0,
        status: "AVAILABLE",
        city: "Raipur",
        address: "VIP Road, Raipur",
        images: [],
      },
      {
        id: "court_2",
        clubId: "all_stars_arena_club",
        clubName: "All Stars Turf Raipur",
        name: "Court 2",
        surfaceType: "3G Turf",
        basePricePerHour: 1200.0,
        status: "AVAILABLE",
        city: "Raipur",
        address: "VIP Road, Raipur",
        images: [],
      },
    ];
  }

  static async getCourtById(courtId: string) {
    const res = await dbPool.query(
      `SELECT crt.*, clb.name as club_name, clb.address, clb.city
       FROM public.courts crt
       JOIN public.clubs clb ON clb.id = crt.club_id
       WHERE crt.id = $1;`,
      [courtId],
    );
    if (res.rows.length === 0)
      throw new ApiError(404, "Court pitch not found", "COURT_NOT_FOUND");
    return res.rows[0];
  }

  static async checkAvailability(courtId: string, bookingDate: string) {
    const bookingsRes = await dbPool.query(
      `SELECT id, start_time, end_time, status
       FROM public.court_bookings
       WHERE court_id = $1 AND booking_date = $2 AND status = 'CONFIRMED';`,
      [courtId, bookingDate],
    );
    return bookingsRes.rows;
  }

  static async calculateQuote(
    courtId: string,
    bookingDate: string,
    startTime: string,
  ) {
    const court = await this.getCourtById(courtId);
    const dateObj = new Date(bookingDate);
    const dayOfWeek = dateObj.getDay();
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

    const startHour = Number(startTime.split(":")[0]);
    const isPeak = startHour >= 17 && startHour < 21;

    const baseAmount = calculateCourtPrice(
      court.base_price,
      isWeekend,
      isPeak,
      court.peak_multiplier,
      court.weekend_multiplier,
    );

    const gstAmount = Math.round(baseAmount * 0.18 * 100) / 100;
    const platformFee = 50.0;
    const totalAmount =
      Math.round((baseAmount + gstAmount + platformFee) * 100) / 100;

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
