import { dbPool } from "../../config/db.config.js";
import { ApiError } from "../../utils/apiResponse.js";

export class AdminService {
  /**
   * Calculates gross revenue, total refunds, and net revenue across all financial tables.
   */
  static async calculateRevenueAndRefundStats() {
    const [
      gamesRevRes,
      courtBookingsRevRes,
      paymentOrdersRevRes,
      txRevRes,
      walletTxRevRes,
      refundsGamesRes,
      refundsTxRes,
      refundsWalletRes,
      refundsBookingsRes,
    ] = await Promise.allSettled([
      // 1. Completed Pitch / Match bookings revenue
      dbPool.query(`
        SELECT COALESCE(SUM(COALESCE(g.entry_fee, 0)), 0) as rev
        FROM public.game_players gp
        JOIN public.games g ON g.id = gp.game_id
        WHERE UPPER(g.status::text) = 'COMPLETED'
          AND UPPER(gp.payment_status::text) IN ('PAID', 'SUCCESS', 'COMPLETED');
      `),
      // 2. Direct Court bookings revenue (completed/confirmed)
      dbPool.query(`
        SELECT COALESCE(SUM(COALESCE(amount_paid, 0)), 0) as rev
        FROM public.court_bookings
        WHERE UPPER(status::text) IN ('COMPLETED', 'CONFIRMED', 'SUCCESS');
      `),
      // 3. Razorpay payment orders
      dbPool.query(`
        SELECT COALESCE(SUM(amount_paise / 100.0), 0) as rev
        FROM public.payment_orders
        WHERE LOWER(status::text) IN ('success', 'paid', 'completed');
      `),
      // 4. Financial ledger
      dbPool.query(`
        SELECT COALESCE(SUM(ABS(amount)), 0) as rev
        FROM public.transactions
        WHERE LOWER(status::text) IN ('success', 'paid', 'completed')
          AND UPPER(type::text) IN ('GAME_FEE', 'BOOKING', 'SLOT_BOOKING', 'ENTRY_FEE')
          AND LOWER(type::text) NOT LIKE '%refund%';
      `),
      // 5. Wallet transactions
      dbPool.query(`
        SELECT COALESCE(SUM(ABS(amount)), 0) as rev
        FROM public.wallet_transactions
        WHERE LOWER(status::text) IN ('success', 'paid', 'completed')
          AND UPPER(transaction_type::text) IN ('GAME_FEE', 'BOOKING', 'SLOT_BOOKING', 'ENTRY_FEE')
          AND LOWER(transaction_type::text) NOT LIKE '%refund%';
      `),
      // 6. Refunds from cancelled games (refunded to player wallet)
      dbPool.query(`
        SELECT COALESCE(SUM(COALESCE(g.entry_fee, 0)), 0) as ref
        FROM public.game_players gp
        JOIN public.games g ON g.id = gp.game_id
        WHERE UPPER(g.status::text) = 'CANCELLED'
          AND UPPER(gp.payment_status::text) IN ('REFUNDED', 'PAID', 'SUCCESS');
      `),
      // 7. Refunds from transactions ledger
      dbPool.query(`
        SELECT COALESCE(SUM(ABS(amount)), 0) as ref
        FROM public.transactions
        WHERE LOWER(type::text) LIKE '%refund%'
           OR LOWER(description) LIKE '%refund%'
           OR LOWER(status::text) LIKE '%refund%';
      `),
      // 8. Refunds from wallet transactions
      dbPool.query(`
        SELECT COALESCE(SUM(ABS(amount)), 0) as ref
        FROM public.wallet_transactions
        WHERE UPPER(status::text) IN ('SUCCESS', 'COMPLETED', 'PAID', 'REFUNDED')
          AND (
            UPPER(transaction_type::text) LIKE '%REFUND%'
            OR LOWER(description) LIKE '%refund%'
            OR LOWER(description) LIKE '%cancelled%'
          );
      `),
      // 9. Cancelled/Refunded direct court bookings
      dbPool.query(`
        SELECT COALESCE(SUM(COALESCE(amount_paid, 0)), 0) as ref
        FROM public.court_bookings
        WHERE LOWER(status::text) IN ('refunded', 'cancelled');
      `),
    ]);

    const gRev =
      gamesRevRes.status === "fulfilled"
        ? Number(gamesRevRes.value.rows[0]?.rev || 0)
        : 0;
    const cbRev =
      courtBookingsRevRes.status === "fulfilled"
        ? Number(courtBookingsRevRes.value.rows[0]?.rev || 0)
        : 0;
    const poRev =
      paymentOrdersRevRes.status === "fulfilled"
        ? Number(paymentOrdersRevRes.value.rows[0]?.rev || 0)
        : 0;
    const txRev =
      txRevRes.status === "fulfilled"
        ? Number(txRevRes.value.rows[0]?.rev || 0)
        : 0;
    const wtRev =
      walletTxRevRes.status === "fulfilled"
        ? Number(walletTxRevRes.value.rows[0]?.rev || 0)
        : 0;

    const completedMatchRevenue = gRev + cbRev;
    let totalRevenue = completedMatchRevenue;
    if (totalRevenue === 0) {
      totalRevenue = Math.max(poRev, txRev, wtRev);
    }

    const gRef =
      refundsGamesRes.status === "fulfilled"
        ? Number(refundsGamesRes.value.rows[0]?.ref || 0)
        : 0;
    const txRef =
      refundsTxRes.status === "fulfilled"
        ? Number(refundsTxRes.value.rows[0]?.ref || 0)
        : 0;
    const wtRef =
      refundsWalletRes.status === "fulfilled"
        ? Number(refundsWalletRes.value.rows[0]?.ref || 0)
        : 0;
    const cbRef =
      refundsBookingsRes.status === "fulfilled"
        ? Number(refundsBookingsRes.value.rows[0]?.ref || 0)
        : 0;

    const cancelledMatchRefunds = gRef + cbRef;
    let totalRefunds = Math.max(cancelledMatchRefunds, wtRef, txRef);

    const netRevenue = totalRevenue + totalRefunds;

    return {
      totalRevenue,
      totalRefunds,
      netRevenue,
    };
  }

  /**
   * Fetches paginated payment records with filtering by status and search terms.
   * Unifies match pitch bookings, direct court bookings, and wallet refund transactions.
   */
  static async fetchPaymentRecords(options: {
    search?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    const { search, status, page = 1, limit = 50 } = options;
    const pageNum = Math.max(Number(page) || 1, 1);
    const limitNum = Math.min(Math.max(Number(limit) || 50, 1), 100);
    const offset = (pageNum - 1) * limitNum;

    const params: any[] = [limitNum, offset];
    let whereClause = "WHERE 1=1";

    if (search && search.trim().length > 0) {
      params.push(`%${search.trim()}%`);
      const searchIdx = params.length;
      whereClause += ` AND (p.user_name ILIKE $${searchIdx} OR p.user_phone ILIKE $${searchIdx} OR p.user_email ILIKE $${searchIdx} OR p.match_title ILIKE $${searchIdx} OR p.id ILIKE $${searchIdx})`;
    }

    if (status && status !== "ALL") {
      const targetStatus = status.toUpperCase();

      if (targetStatus === "CONFIRMED" || targetStatus === "SUCCESS") {
        whereClause += ` AND LOWER(p.status) IN ('confirmed', 'completed', 'paid', 'success')`;
      } else if (targetStatus === "CANCELLED") {
        whereClause += ` AND (LOWER(p.status) IN ('cancelled', 'refunded') OR p.refund_amount > 0)`;
      } else if (targetStatus === "REFUNDED") {
        whereClause += ` AND (LOWER(p.status) IN ('refunded', 'refund_pending') OR p.refund_amount > 0)`;
      } else {
        params.push(targetStatus);
        const statusIdx = params.length;
        whereClause += ` AND UPPER(p.status) = $${statusIdx}`;
      }
    }

    const query = `
      WITH all_payments AS (
        -- 1. Pitch / Match bookings created by players
        SELECT
          g.id,
          g.creator_id as user_id,
          COALESCE(u.name, 'Player') as user_name,
          COALESCE(u.email, '') as user_email,
          COALESCE(u.phone, '') as user_phone,
          u.profile_image_url as user_avatar,
          COALESCE(g.entry_fee, 0) as amount,
          CASE
            WHEN g.status::text = 'CANCELLED' THEN 'REFUNDED'
            WHEN g.status::text = 'COMPLETED' THEN 'COMPLETED'
            ELSE 'CONFIRMED'
          END as status,
          'PITCH_BOOKING' as type,
          g.id as match_id,
          COALESCE(g.title, 'Pitch Booking Match') as match_title,
          COALESCE(
            NULLIF(TRIM(CONCAT(TO_CHAR(g.match_date, 'YYYY-MM-DD'), ' ', TO_CHAR(g.start_time, 'HH24:MI:SS'))), ''),
            g.created_at::text
          ) as match_time,
          COALESCE(c.name, 'Smash Up India') as club_name,
          COALESCE(crt.name, CASE WHEN g.court_id = 'padel_court_1' THEN 'Padel Court 1' WHEN g.court_id = 'court_3' THEN 'Court 3' WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END) as court_name,
          CASE
            WHEN g.team_a_score IS NOT NULL AND g.team_b_score IS NOT NULL
              THEN CONCAT(g.team_a_score::text, ' - ', g.team_b_score::text)
            ELSE '0 - 0'
          END as score,
          COALESCE(
            (SELECT gv_sub.video_url FROM public.game_videos gv_sub WHERE gv_sub.game_id = g.id AND gv_sub.video_url IS NOT NULL AND gv_sub.video_url != '' ORDER BY gv_sub.created_at DESC LIMIT 1),
            g.video_playback_url
          ) as video_url,
          (
            EXISTS (SELECT 1 FROM public.game_videos gv_sub WHERE gv_sub.game_id = g.id AND gv_sub.video_url IS NOT NULL AND gv_sub.video_url != '')
            OR (g.video_playback_url IS NOT NULL AND g.video_playback_url != '')
          ) as has_video,
          CASE
            WHEN g.status::text = 'CANCELLED' THEN COALESCE(g.entry_fee, 0)
            ELSE 0
          END as refund_amount,
          CASE
            WHEN g.status::text = 'CANCELLED' 
              THEN COALESCE(g.cancellation_reason, 'Match cancelled - ₹' || g.entry_fee::text || ' refunded to player wallet')
            ELSE NULL
          END as refund_reason,
          g.created_at
        FROM public.games g
        LEFT JOIN public.users u ON u.id = g.creator_id
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        LEFT JOIN public.clubs c ON c.id = COALESCE(crt.club_id, g.club_id, 'smash_up_india_club')
        WHERE COALESCE(g.entry_fee, 0) > 0

        UNION ALL

        -- 2. Direct court slot bookings
        SELECT
          cb.id,
          cb.user_id,
          COALESCE(u.name, 'Player') as user_name,
          COALESCE(u.email, '') as user_email,
          COALESCE(u.phone, '') as user_phone,
          u.profile_image_url as user_avatar,
          COALESCE(cb.amount_paid, 0) as amount,
          cb.status::text as status,
          'SLOT_BOOKING' as type,
          NULL as match_id,
          'Court Slot Booking' as match_title,
          COALESCE(
            NULLIF(TRIM(CONCAT(TO_CHAR(cb.booking_date, 'YYYY-MM-DD'), ' ', TO_CHAR(cb.start_time, 'HH24:MI:SS'))), ''),
            cb.created_at::text
          ) as match_time,
          COALESCE(c.name, 'Smash Up India') as club_name,
          COALESCE(crt.name, 'Main Arena Court') as court_name,
          'N/A' as score,
          NULL as video_url,
          false as has_video,
          CASE
            WHEN LOWER(cb.status::text) IN ('cancelled', 'refunded', 'refund_pending')
              THEN COALESCE(cb.refund_amount, cb.amount_paid, 0)
            ELSE 0
          END as refund_amount,
          COALESCE(cb.cancellation_reason, cb.rejection_reason, 'Slot booking cancelled and refunded to wallet') as refund_reason,
          cb.created_at
        FROM public.court_bookings cb
        LEFT JOIN public.users u ON u.id = cb.user_id
        LEFT JOIN public.courts crt ON crt.id = cb.court_id
        LEFT JOIN public.clubs c ON c.id = cb.club_id

        UNION ALL

        -- 3. Standalone wallet transactions (Refunds & Topups)
        SELECT
          wt.id,
          wt.user_id,
          COALESCE(u.name, 'Player') as user_name,
          COALESCE(u.email, '') as user_email,
          COALESCE(u.phone, '') as user_phone,
          u.profile_image_url as user_avatar,
          ABS(wt.amount) as amount,
          wt.status::text as status,
          CASE WHEN wt.transaction_type::text ILIKE '%REFUND%' OR wt.description ILIKE '%REFUND%' THEN 'REFUND' ELSE 'WALLET_TOPUP' END as type,
          NULL as match_id,
          wt.description as match_title,
          wt.created_at::text as match_time,
          'Smash Up India' as club_name,
          'Online Wallet' as court_name,
          'N/A' as score,
          NULL as video_url,
          false as has_video,
          CASE WHEN wt.transaction_type::text ILIKE '%REFUND%' OR wt.description ILIKE '%REFUND%' THEN ABS(wt.amount) ELSE 0 END as refund_amount,
          wt.description as refund_reason,
          wt.created_at
        FROM public.wallet_transactions wt
        LEFT JOIN public.users u ON u.id = wt.user_id
        WHERE (
          wt.transaction_type::text = 'REFUND'
          OR wt.transaction_type::text = 'WALLET_TOPUP'
        )
        AND (wt.reference_id IS NULL OR wt.reference_id NOT LIKE 'MATCH_HOST_REFUND:%')
      )
      SELECT *
      FROM all_payments p
      ${whereClause}
      ORDER BY p.created_at DESC
      LIMIT $1 OFFSET $2;
    `;

    const paymentsRes = await dbPool.query(query, params);

    return paymentsRes.rows.map((r: any) => ({
      id: r.id,
      userId: r.user_id,
      userName: r.user_name,
      userEmail: r.user_email,
      userPhone: r.user_phone,
      userAvatar: r.user_avatar,
      amount: Number(r.amount || 0),
      status: String(r.status || "CONFIRMED").toUpperCase(),
      type: r.type,
      matchId: r.match_id,
      matchTitle: r.match_title,
      matchTime: r.match_time,
      clubName: r.club_name,
      courtName: r.court_name,
      score: r.score,
      videoUrl: r.video_url,
      hasVideo: Boolean(r.has_video),
      refundAmount: Number(r.refund_amount || 0),
      refundReason: r.refund_reason,
      createdAt: r.created_at,
    }));
  }

  /**
   * Processes a refund for a pitch booking, match booking, court booking, or wallet transaction.
   * Accurately credits the player's wallet and records audit logs and notifications.
   */
  static async processRefund(
    paymentId: string,
    reason: string,
    adminId: string,
    adminName: string,
    ipAddress: string,
  ) {
    let amountToRefund = 0;
    let targetUserId = "";
    let matchTitle = "Pitch Booking";

    // 1. Check if this is a game / pitch booking
    const gameRes = await dbPool.query(
      `SELECT * FROM public.games WHERE id = $1 FOR UPDATE;`,
      [paymentId],
    );

    if (gameRes.rows.length > 0) {
      const game = gameRes.rows[0];
      amountToRefund = Number(game.entry_fee || 0);
      targetUserId = game.creator_id;
      matchTitle = game.title || "Pitch Booking";

      await dbPool.query(
        `UPDATE public.games 
         SET status = 'CANCELLED', cancellation_reason = $2, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $1;`,
        [paymentId, reason],
      );

      await dbPool.query(
        `UPDATE public.game_players 
         SET payment_status = 'REFUNDED' 
         WHERE game_id = $1 AND user_id = $2;`,
        [paymentId, targetUserId],
      );
    } else {
      // 2. Check direct court bookings
      const bookingRes = await dbPool.query(
        `SELECT * FROM public.court_bookings WHERE id = $1 FOR UPDATE;`,
        [paymentId],
      );

      if (bookingRes.rows.length > 0) {
        const booking = bookingRes.rows[0];
        amountToRefund = Number(booking.amount_paid || 0);
        targetUserId = booking.user_id;

        await dbPool.query(
          `UPDATE public.court_bookings 
           SET status = 'REFUNDED', refund_amount = $2, refunded_at = CURRENT_TIMESTAMP, cancellation_reason = $3 
           WHERE id = $1;`,
          [paymentId, amountToRefund, reason],
        );
      } else {
        // 3. Check wallet transactions
        const wtRes = await dbPool.query(
          `SELECT * FROM public.wallet_transactions WHERE id = $1;`,
          [paymentId],
        );
        if (wtRes.rows.length > 0) {
          amountToRefund = Number(wtRes.rows[0].amount || 0);
          targetUserId = wtRes.rows[0].user_id;
        }
      }
    }

    if (amountToRefund > 0 && targetUserId) {
      const refId = `ADMIN_REFUND:${paymentId}:${targetUserId}`;
      const refundDesc = `Pitch booking refund for cancelled match (${matchTitle}): ${reason}`;

      const txRes = await dbPool.query(
        `INSERT INTO public.transactions (user_id, type, amount, status, description, reference_id)
         VALUES ($1, 'REFUND', $2, 'SUCCESS', $3, $4)
         RETURNING id, balance_after;`,
        [targetUserId, amountToRefund, refundDesc, refId],
      );

      const newBal = Number(txRes.rows[0]?.balance_after || 0);

      await dbPool.query(
        `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
         VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
         ON CONFLICT (id) DO NOTHING;`,
        [
          txRes.rows[0]?.id,
          targetUserId,
          amountToRefund,
          newBal,
          refundDesc,
          refId,
        ],
      );

      // Realtime wallet update & user notification
      try {
        const { sendWalletUpdate, sendUserNotification } =
          await import("../../services/realtime.service.js");
        sendWalletUpdate(targetUserId, { walletBalance: newBal });
        sendUserNotification(targetUserId, {
          title: "💰 Pitch Booking Refund Credited",
          message: `₹${amountToRefund.toFixed(2)} refunded to your wallet for ${matchTitle}. Reason: ${reason}`,
          type: "REFUND",
        });
      } catch (_) {}
    }

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, user_id, action, target, details, ip_address)
       VALUES ($1, $2, $3, 'PAYMENT_REFUND_PROCESSED', $4, $5, $6);`,
      [
        adminId,
        adminName,
        targetUserId || null,
        paymentId,
        `Refund of ₹${amountToRefund} processed to player wallet for ${paymentId}. Reason: ${reason}`,
        ipAddress || "127.0.0.1",
      ],
    );

    return {
      paymentId,
      refundAmount: amountToRefund,
      status: "REFUNDED",
    };
  }
}
