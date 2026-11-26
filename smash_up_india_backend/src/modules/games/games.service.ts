import crypto from "crypto";
import { dbPool } from "../../config/db.config.js";
import { GamesRepository } from "./games.repository.js";
import { CourtsService } from "../courts/courts.service.js";
import { getSignedPlaybackUrl } from "../../services/storage.service.js";
import {
  joinGameWithWallet,
  verifyUserWalletPin,
} from "../../services/wallet.service.js";
import {
  sendUserNotification,
  sendWalletUpdate,
} from "../../services/realtime.service.js";
import { NotificationService } from "../notifications/notifications.service.js";
import { getSocketIO, SOCKET_EVENTS } from "../../config/socket.config.js";
import { ApiError } from "../../utils/apiResponse.js";
import { logger } from "../../utils/logger.js";
import { razorpayClient } from "../../services/razorpay.service.js";
import { env } from "../../config/env.config.js";

const FORMAT_PLAYER_COUNTS: Record<string, number> = {
  "1v1": 2,
  "2v2": 4,
  "3v3": 6,
  "4v4": 8,
  "5v5": 10,
  "6v6": 12,
  "7v7": 14,
  "8v8": 16,
  "9v9": 18,
  "11v11": 22,
};

const SKILL_LEVEL_MAP: Record<string, string> = {
  AMATEUR: "Beginner",
  BEGINNER: "Beginner",
  INTERMEDIATE: "Intermediate",
  SEMI_PRO: "Intermediate",
  ADVANCED: "Advanced",
  PRO: "Professional",
  PROFESSIONAL: "Professional",
  ANY: "Beginner",
};

export class GamesService {
  static async createMatchRazorpayOrder(
    userId: string,
    amountRupees: number,
    gameId?: string,
    purpose: string = "MATCH_JOIN",
  ) {
    if (gameId) {
      const gameRes = await dbPool.query(
        `SELECT id, entry_fee, COALESCE(per_player_fee, 0.00) as per_player_fee, format, status FROM public.games WHERE id = $1;`,
        [gameId],
      );
      if (gameRes.rows.length === 0) {
        throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
      }
      const game = gameRes.rows[0];
      if (game.status === "CANCELLED" || game.status === "COMPLETED") {
        throw new ApiError(
          400,
          `Cannot join a match that is ${game.status}`,
          "INVALID_MATCH_STATUS",
        );
      }
      const matchFee = parseFloat(
        game.created_by_player
          ? game.per_player_fee || "0.00"
          : game.per_player_fee || game.entry_fee || "0.00",
      );
      if (matchFee > 0) {
        amountRupees = matchFee;
      }
    }

    if (amountRupees <= 0) {
      throw new ApiError(
        400,
        "Match is free or fee is invalid",
        "INVALID_AMOUNT",
      );
    }

    const amountPaise = Math.round(amountRupees * 100);
    const keyId = env.RAZORPAY_KEY_ID || "rzp_test_Sb44esbmpGlzBd";
    const paymentOrderId = `pay_ord_${crypto.randomBytes(8).toString("hex")}`;
    let razorpayOrderId = `rzp_order_mock_${Date.now()}`;
    const dbPurpose = gameId ? "MATCH_JOIN" : "MATCH_CREATION";

    try {
      if (
        keyId &&
        env.RAZORPAY_KEY_SECRET &&
        !keyId.includes("dummy") &&
        !keyId.includes("123456")
      ) {
        const rzpOrder = await razorpayClient.orders.create({
          amount: amountPaise,
          currency: "INR",
          receipt: paymentOrderId,
          notes: {
            userId,
            gameId: gameId || "new_game",
            purpose: dbPurpose,
            paymentOrderId,
          },
        });
        razorpayOrderId = rzpOrder.id;
      }
    } catch (err: any) {
      logger.warn(
        `Razorpay Match Order SDK Notice (${err.message}). Using fallback order ID.`,
      );
    }

    await dbPool.query(
      `INSERT INTO public.payment_orders (
         id, user_id, provider, provider_order_id, idempotency_key,
         amount_paise, currency, purpose, status, metadata, expires_at
       ) VALUES ($1, $2, 'RAZORPAY', $3, $4, $5, 'INR', $6, 'PENDING', $7, CURRENT_TIMESTAMP + INTERVAL '30 minutes')
       ON CONFLICT (id) DO UPDATE 
       SET provider_order_id = EXCLUDED.provider_order_id, updated_at = CURRENT_TIMESTAMP;`,
      [
        paymentOrderId,
        userId,
        razorpayOrderId,
        paymentOrderId,
        amountPaise,
        dbPurpose,
        JSON.stringify({ gameId, userId, amountRupees }),
      ],
    );

    const userRes = await dbPool.query(
      "SELECT name, email, phone FROM public.users WHERE id = $1;",
      [userId],
    );
    const user = userRes.rows[0];

    return {
      paymentOrderId,
      orderId: razorpayOrderId,
      razorpayOrderId,
      keyId,
      razorpayKeyId: keyId,
      amountRupees,
      amountPaise,
      amountPaisa: amountPaise,
      currency: "INR",
      prefill: {
        name: user?.name || "Player",
        email: user?.email || "",
        contact: user?.phone || "",
      },
    };
  }

  static async createPlayerGame(
    creatorUserId: string,
    data: {
      title: string;
      clubId: string;
      courtId: string;
      format: string;
      maxPlayers?: number;
      reservePlayersCount?: number;
      entryFee: number;
      skillRequirement?: string;
      privacy?: string;
      matchDate: string;
      startTime: string;
      endTime: string;
      description?: string;
      cctvRecordingEnabled?: boolean;
      paymentMethod?: string;
      paymentReference?: string;
      walletPin?: string;
      paymentOrderId?: string;
      razorpayPaymentId?: string;
      razorpayOrderId?: string;
      razorpaySignature?: string;
    },
  ) {
    const userRes = await dbPool.query(
      `SELECT id, status, role_id FROM public.users WHERE id = $1;`,
      [creatorUserId],
    );
    if (userRes.rows.length === 0 || userRes.rows[0].status !== "ACTIVE") {
      throw new ApiError(403, "User account is not active", "INACTIVE_USER");
    }
    const creatorRoleId = Number(userRes.rows[0].role_id);
    const isPlayerCreator = creatorRoleId === 3;
    const creatorRoleName = isPlayerCreator
      ? "PLAYER"
      : creatorRoleId === 2
        ? "MANAGER"
        : "ADMIN";

    data.clubId = "smash_up_india_club";

    const courtInput = (data.courtId || (data as any).courtName || "")
      .toString()
      .trim();
    data.courtId = CourtsService.normalizeCourtId(courtInput);

    const courtRes = await dbPool.query(
      `SELECT id, name, club_id, status FROM public.courts WHERE id = $1;`,
      [data.courtId],
    );
    if (courtRes.rows.length === 0) {
      throw new ApiError(
        404,
        `Selected court (${data.courtId}) not found`,
        "COURT_NOT_FOUND",
      );
    } else {
      const cStatus = (courtRes.rows[0].status || "").toUpperCase();
      if (cStatus === "MAINTENANCE" || cStatus === "BLOCKED") {
        throw new ApiError(
          400,
          `Court ${courtRes.rows[0].name} is currently in ${cStatus} status and cannot be booked. Please select an active available court pitch.`,
          "COURT_UNAVAILABLE",
        );
      }
    }
    const resolvedCourtName =
      courtRes.rows[0].name || CourtsService.getCourtDisplayName(data.courtId);

    const formatKey = (data.format || "11v11").toLowerCase().trim();
    const expectedPlayers = FORMAT_PLAYER_COUNTS[formatKey] || 22;
    const maxPlayers = data.maxPlayers || expectedPlayers;

    if (maxPlayers % 2 !== 0) {
      throw new ApiError(
        400,
        "Max players must be an even number for balanced team sides",
      );
    }

    const entryFee =
      data.entryFee !== undefined ? Number(data.entryFee) : 200.0;
    if (entryFee < 0) {
      throw new ApiError(400, "Entry fee cannot be negative");
    }

    const cctvRecordingEnabled = Boolean(data.cctvRecordingEnabled);
    const cctvRecordingFee = cctvRecordingEnabled ? 100.0 : 0.0;
    if (isPlayerCreator && cctvRecordingEnabled) {
      if (entryFee < cctvRecordingFee) {
        throw new ApiError(
          400,
          "CCTV video recording requires ₹100 extra payment",
          "CCTV_PAYMENT_REQUIRED",
        );
      }
      if (
        data.paymentMethod !== "WALLET" &&
        data.paymentMethod !== "RAZORPAY"
      ) {
        throw new ApiError(
          400,
          "Valid payment method (WALLET or RAZORPAY) is required for CCTV video recording",
          "PAYMENT_REQUIRED",
        );
      }
    }

    const cleanDate = (data.matchDate || "").includes("T")
      ? data.matchDate.split("T")[0].trim()
      : (data.matchDate || "").trim();
    const padTime = (t: string) => {
      const parts = (t || "").trim().split(":");
      const hh = (parts[0] || "0").padStart(2, "0");
      const mm = (parts[1] || "0").padStart(2, "0");
      const ss = (parts[2] || "00").slice(0, 2).padStart(2, "0");
      return `${hh}:${mm}:${ss}`;
    };
    const cleanStart = padTime(data.startTime);
    const cleanEnd = padTime(data.endTime);

    const matchStart = new Date(`${cleanDate}T${cleanStart}+05:30`);
    const matchEnd = new Date(`${cleanDate}T${cleanEnd}+05:30`);
    const now = new Date();

    if (isNaN(matchStart.getTime()) || isNaN(matchEnd.getTime())) {
      throw new ApiError(400, "Invalid match date or time format");
    }

    if (matchStart.getTime() < now.getTime() - 2 * 60 * 1000) {
      throw new ApiError(
        400,
        "Cannot book a court slot in the past. Match date and start time must be in the future.",
        "PAST_SLOT_NOT_ALLOWED",
      );
    }

    if (matchEnd <= matchStart) {
      throw new ApiError(
        400,
        "Match end time must be strictly after start time",
      );
    }

    const hasOverlap = await GamesRepository.checkCourtOverlap(
      data.courtId,
      data.matchDate,
      data.startTime,
      data.endTime,
    );

    if (hasOverlap) {
      throw new ApiError(
        409,
        "This court is already booked or occupied for the selected time slot",
      );
    }

    const skillReq =
      SKILL_LEVEL_MAP[(data.skillRequirement || "ANY").toUpperCase()] ||
      "Beginner";

    const client = await dbPool.connect();
    let newGame: any = null;

    try {
      await client.query("BEGIN");

      const overlapLock = await client.query(
        `SELECT id, title, start_time, end_time FROM public.games
         WHERE court_id = $1 AND match_date = $2 
           AND status <> 'CANCELLED' AND approval_status <> 'REJECTED'
           AND (start_time < $4::time AND end_time > $3::time)
         FOR UPDATE;`,
        [data.courtId, data.matchDate, data.startTime, data.endTime],
      );
      if (overlapLock.rows.length > 0) {
        throw new ApiError(
          409,
          `${resolvedCourtName} was just booked by another player for the selected time slot (${data.startTime} - ${data.endTime})`,
          "COURT_OCCUPIED",
        );
      }

      const bookingOverlapLock = await client.query(
        `SELECT id, start_time, end_time FROM public.court_bookings
         WHERE court_id = $1 AND booking_date = $2 AND status = 'CONFIRMED'
           AND (start_time < $4::time AND end_time > $3::time)
         FOR UPDATE;`,
        [data.courtId, data.matchDate, data.startTime, data.endTime],
      );
      if (bookingOverlapLock.rows.length > 0) {
        throw new ApiError(
          409,
          `${resolvedCourtName} was just booked for the selected time slot (${data.startTime} - ${data.endTime})`,
          "COURT_OCCUPIED",
        );
      }

      const targetGameId = "gam_" + crypto.randomBytes(8).toString("hex");

      newGame = await GamesRepository.createGame(
        {
          id: targetGameId,
          title: data.title || "Pitch Booking",
          courtId: data.courtId,
          creatorId: creatorUserId,
          creatorRoleName,
          createdByPlayer: isPlayerCreator,
          format: formatKey,
          entryFee,
          matchDate: data.matchDate,
          startTime: data.startTime,
          endTime: data.endTime,
          description: data.description,
          cctvRecordingEnabled,
          cctvRecordingFee,
        },
        client,
      );

      newGame.club_id = "smash_up_india_club";
      newGame.club_name = "Smash Up India";
      newGame.court_name = resolvedCourtName;
      newGame.max_players = maxPlayers;
      newGame.privacy = "PUBLIC";
      newGame.skill_requirement = skillReq;

      if (isPlayerCreator) {
        const initialPosition = ((data as any).position || "ST").toUpperCase();
        let paymentStatus = "HOST_FREE";

        let paymentMethodRecorded = "FREE";
        let paymentRefRecorded: string | null = null;

        if (entryFee > 0) {
          if (data.paymentMethod === "WALLET") {
            if (data.walletPin) {
              const pinValid = await verifyUserWalletPin(
                creatorUserId,
                data.walletPin,
              );
              if (!pinValid) {
                throw new ApiError(
                  400,
                  "Incorrect wallet PIN",
                  "INVALID_WALLET_PIN",
                );
              }
            }
            const walletRes = await client.query(
              `SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1 FOR UPDATE;`,
              [creatorUserId],
            );
            const currentBalance = parseFloat(
              walletRes.rows[0]?.wallet_balance || "0.00",
            );
            if (currentBalance < entryFee) {
              throw new ApiError(
                400,
                `Insufficient wallet balance. Available: ₹${currentBalance.toFixed(2)}, Required: ₹${entryFee.toFixed(2)}`,
                "INSUFFICIENT_WALLET_BALANCE",
              );
            }

            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'PAYMENT', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [
                creatorUserId,
                entryFee,
                `Host entry fee for match "${newGame.title || "Pickle Match"}"`,
                targetGameId,
              ],
            );
            const newBalance = parseFloat(
              txRes.rows[0]?.balance_after || "0.00",
            );

            await client.query(
              `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
               VALUES ($1, $2, 'DEBIT', $3, $4, $5, 'SUCCESS', $6)
               ON CONFLICT (id) DO NOTHING;`,
              [
                txRes.rows[0]?.id,
                creatorUserId,
                entryFee,
                newBalance,
                `Host entry fee for match "${newGame.title || "Pickle Match"}"`,
                targetGameId,
              ],
            );

            sendWalletUpdate(creatorUserId, { walletBalance: newBalance });
            paymentStatus = "PAID";
            paymentMethodRecorded = "WALLET";
            paymentRefRecorded = txRes.rows[0]?.id;
          } else if (data.paymentMethod === "RAZORPAY") {
            const razorId =
              data.razorpayPaymentId ||
              data.paymentReference ||
              data.razorpayOrderId;
            logger.info(
              `Host player ${creatorUserId} created game ${targetGameId} via Razorpay reference ${razorId}`,
            );

            if (
              data.razorpayOrderId &&
              data.razorpayPaymentId &&
              data.razorpaySignature &&
              !data.razorpayOrderId.startsWith("rzp_order_mock_")
            ) {
              const secret =
                env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
              const generatedSig = crypto
                .createHmac("sha256", secret)
                .update(`${data.razorpayOrderId}|${data.razorpayPaymentId}`)
                .digest("hex");
              if (generatedSig !== data.razorpaySignature) {
                throw new ApiError(
                  400,
                  "Invalid Razorpay payment signature",
                  "INVALID_SIGNATURE",
                );
              }
            }

            const razorOrderId = data.razorpayOrderId || data.paymentOrderId;
            if (razorOrderId) {
              await client.query(
                `UPDATE public.payment_orders 
                 SET status = 'PAID', paid_at = CURRENT_TIMESTAMP, provider_payment_id = $1, updated_at = CURRENT_TIMESTAMP 
                 WHERE (provider_order_id = $2 OR id = $2) AND user_id = $3;`,
                [
                  data.razorpayPaymentId || razorId,
                  razorOrderId,
                  creatorUserId,
                ],
              );
            }

            paymentStatus = "PAID";
            paymentMethodRecorded = "RAZORPAY";
            paymentRefRecorded = razorId || null;
          }
        }

        await client.query(
          `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method, payment_reference)
           VALUES ($1, $2, 'TEAM_A', $3, $4, $5, $6)
           ON CONFLICT (game_id, user_id) DO UPDATE 
           SET payment_status = EXCLUDED.payment_status,
               payment_method = EXCLUDED.payment_method,
               payment_reference = EXCLUDED.payment_reference;`,
          [
            targetGameId,
            creatorUserId,
            initialPosition,
            paymentStatus,
            paymentMethodRecorded,
            paymentRefRecorded,
          ],
        );
      }

      await GamesRepository.addActivityLog(
        {
          gameId: newGame.id,
          actorId: creatorUserId,
          actorRoleName: creatorRoleName,
          actionType: "MATCH_CREATED",
          details: `${creatorRoleName} hosted new match: ${newGame.title}`,
        },
        client,
      );

      try {
        const creatorUserRes = await client.query(
          `SELECT name FROM public.users WHERE id = $1;`,
          [creatorUserId],
        );
        const creatorUserName = creatorUserRes.rows[0]?.name || creatorRoleName;
        const matchCreateDetails = `Match "${newGame.title || "Match"}" created by ${creatorUserName}. Host: ${creatorUserName}. Scheduled: ${data.matchDate} at ${data.startTime}. Entry Fee: ₹${entryFee}. Court: ${newGame.court_name || data.courtId}. Format: ${formatKey}`;

        await client.query(
          `INSERT INTO public.audit_logs (admin_id, admin_name, user_id, action, target, details)
           VALUES ($1, $2, $3, 'MATCH_CREATED', $4, $5);`,
          [
            isPlayerCreator ? null : creatorUserId,
            creatorUserName,
            creatorUserId,
            newGame.title || "Match",
            matchCreateDetails,
          ],
        );
      } catch (_) {}

      await client.query("COMMIT");
    } catch (err: any) {
      await client.query("ROLLBACK");
      if (
        err.code === "23505" ||
        err.message?.includes("already booked") ||
        err.message?.includes("Overlapping time slots")
      ) {
        throw new ApiError(
          409,
          err.message ||
            "This court pitch is already booked or occupied for the selected time slot. Please choose another slot or court.",
          "COURT_SLOT_CONFLICT",
        );
      }
      throw err;
    } finally {
      client.release();
    }

    sendUserNotification(creatorUserId, {
      title: "⚽ Game Created",
      message: `Your game "${newGame.title}" has been created!`,
      type: "SUCCESS",
    });

    // Notify all active managers with player name, court name, match date/time and amount paid
    try {
      const playerRes = await dbPool.query(
        `SELECT name, phone FROM public.users WHERE id = $1;`,
        [creatorUserId],
      );
      const playerName = playerRes.rows[0]?.name || "Player";
      const formattedAmount = `₹${entryFee.toFixed(0)}`;
      const courtDisplayName =
        newGame.court_name || CourtsService.getCourtDisplayName(data.courtId);

      const mgrRes = await dbPool.query(
        `SELECT DISTINCT u.id as user_id
         FROM public.users u
         LEFT JOIN public.club_managers cm ON cm.user_id = u.id
         WHERE (u.role_id = 2 AND u.status = 'ACTIVE')
            OR (cm.club_id = $1 AND u.status = 'ACTIVE');`,
        [newGame.club_id || "smash_up_india_club"],
      );

      const notifTitle = "⚽ New Pitch Booking";
      const notifBody = `Player "${playerName}" booked & created match "${newGame.title}" on ${courtDisplayName} (${cleanDate} ${cleanStart}). Amount Paid: ${formattedAmount} via ${data.paymentMethod || "WALLET"}${cctvRecordingEnabled ? " (Includes ₹100 CCTV Video Recording)" : ""}.`;

      for (const mgr of mgrRes.rows) {
        await NotificationService.createNotification({
          userId: mgr.user_id,
          title: notifTitle,
          body: notifBody,
          message: notifBody,
          type: "MATCH_BOOKING",
          clubId: newGame.club_id || "smash_up_india_club",
          gameId: newGame.id,
          data: {
            gameId: newGame.id,
            playerName,
            creatorUserId,
            amountPaid: entryFee,
            formattedAmount,
            courtName: courtDisplayName,
            matchDate: cleanDate,
            startTime: cleanStart,
            paymentMethod: data.paymentMethod || "WALLET",
            route: "/manager/notifications",
          },
        });
      }

      const io = getSocketIO();
      if (io) {
        io.emit(SOCKET_EVENTS.MATCH_LIVE_FEED, {
          gameId: newGame.id,
          action: "MATCH_BOOKED",
          playerName,
          amountPaid: entryFee,
          formattedAmount,
          courtName: courtDisplayName,
        });
      }
    } catch (mgrErr: any) {
      logger.warn(
        `Failed to notify managers for match booking ${newGame.id}: ${mgrErr.message}`,
      );
    }

    return newGame;
  }

  static async joinGame(
    userId: string,
    gameId: string,
    position: string,
    paymentDetails?: {
      paymentMethod?: string;
      walletPin?: string;
      razorpayOrderId?: string;
      razorpayPaymentId?: string;
      razorpaySignature?: string;
    },
  ) {
    const client = await dbPool.connect();
    let newBalance: number | null = null;
    let rosterId: string | null = null;
    let game: any = null;

    try {
      await client.query("BEGIN");

      const gameRes = await client.query(
        `SELECT * FROM public.games WHERE id = $1 FOR UPDATE;`,
        [gameId],
      );
      if (gameRes.rows.length === 0) {
        throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
      }
      game = gameRes.rows[0];

      if (game.status === "CANCELLED" || game.status === "COMPLETED") {
        throw new ApiError(
          400,
          `Cannot join a match that is ${game.status}`,
          "INVALID_MATCH_STATUS",
        );
      }

      if (game.approval_status && game.approval_status !== "APPROVED") {
        throw new ApiError(
          400,
          "Cannot join match that is pending manager approval or rejected",
          "MATCH_NOT_APPROVED",
        );
      }

      const userRes = await client.query(
        `SELECT id, status, role_id FROM public.users WHERE id = $1;`,
        [userId],
      );
      if (userRes.rows.length === 0 || userRes.rows[0].status === "SUSPENDED") {
        throw new ApiError(
          403,
          "Your account is blocked or suspended. You cannot join matches.",
          "ACCOUNT_SUSPENDED",
        );
      }
      if (Number(userRes.rows[0].role_id) !== 3) {
        throw new ApiError(
          403,
          "Managers cannot join or play matches as players",
          "MANAGER_CANNOT_PLAY",
        );
      }

      const existingPlayerRes = await client.query(
        `SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
        [gameId, userId],
      );
      if (existingPlayerRes.rows.length > 0) {
        throw new ApiError(
          400,
          "You have already joined this match roster",
          "ALREADY_JOINED",
        );
      }

      const countRes = await client.query(
        `SELECT COUNT(*) as current_count FROM public.game_players WHERE game_id = $1;`,
        [gameId],
      );
      const currentPlayersCount = parseInt(
        countRes.rows[0]?.current_count || "0",
        10,
      );
      const maxPlayers =
        game.max_players || FORMAT_PLAYER_COUNTS[game.format] || 22;
      if (currentPlayersCount >= maxPlayers) {
        throw new ApiError(
          400,
          "Match is already at full player capacity",
          "MATCH_FULL",
        );
      }

      const entryFee = parseFloat(
        game.created_by_player
          ? game.per_player_fee || "0.00"
          : game.per_player_fee || game.entry_fee || "0.00",
      );
      const paymentMethod =
        paymentDetails?.paymentMethod || (entryFee > 0 ? "WALLET" : "FREE");
      let paymentMethodRecorded =
        entryFee > 0
          ? paymentMethod === "RAZORPAY"
            ? "RAZORPAY"
            : "WALLET"
          : "FREE";
      let paymentRefRecorded: string | null = null;

      if (entryFee > 0) {
        if (paymentMethod === "WALLET") {
          if (paymentDetails?.walletPin) {
            const isPinValid = await verifyUserWalletPin(
              userId,
              paymentDetails.walletPin,
            );
            if (!isPinValid) {
              throw new ApiError(
                400,
                "Incorrect wallet PIN",
                "INVALID_WALLET_PIN",
              );
            }
          }

          const walletRes = await client.query(
            `SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1 FOR UPDATE;`,
            [userId],
          );
          const currentBalance = parseFloat(
            walletRes.rows[0]?.wallet_balance || "0.00",
          );
          if (currentBalance < entryFee) {
            throw new ApiError(
              400,
              `Insufficient wallet balance. Available balance: ₹${currentBalance.toFixed(2)}, Required: ₹${entryFee.toFixed(2)}`,
              "INSUFFICIENT_WALLET_BALANCE",
            );
          }

          const txRes = await client.query(
            `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
             VALUES ($1, 'PAYMENT', $2, 0, 'SUCCESS', $3, $4)
             RETURNING id, balance_after;`,
            [
              userId,
              entryFee,
              `Entry fee for joining match "${game.title || "Pickle Match"}"`,
              gameId,
            ],
          );
          newBalance = parseFloat(txRes.rows[0]?.balance_after || "0.00");

          await client.query(
            `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
             VALUES ($1, $2, 'DEBIT', $3, $4, $5, 'SUCCESS', $6)
             ON CONFLICT (id) DO NOTHING;`,
            [
              txRes.rows[0]?.id,
              userId,
              entryFee,
              newBalance,
              `Entry fee for joining match "${game.title || "Pickle Match"}"`,
              gameId,
            ],
          );

          paymentMethodRecorded = "WALLET";
          paymentRefRecorded = txRes.rows[0]?.id;
        } else if (paymentMethod === "RAZORPAY") {
          if (
            !paymentDetails?.razorpayPaymentId ||
            !paymentDetails?.razorpayOrderId
          ) {
            throw new ApiError(
              400,
              "Razorpay payment details (order ID and payment ID) are required",
              "MISSING_PAYMENT_DETAILS",
            );
          }

          const razorId = paymentDetails.razorpayPaymentId;
          const razorOrderId = paymentDetails.razorpayOrderId;

          if (
            paymentDetails.razorpaySignature &&
            !razorOrderId.startsWith("rzp_order_mock_")
          ) {
            const secret =
              env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
            const generatedSignature = crypto
              .createHmac("sha256", secret)
              .update(`${razorOrderId}|${razorId}`)
              .digest("hex");

            if (generatedSignature !== paymentDetails.razorpaySignature) {
              throw new ApiError(
                400,
                "Invalid Razorpay payment signature",
                "INVALID_SIGNATURE",
              );
            }
          }

          const poRes = await client.query(
            `SELECT id, user_id, amount_paise, status, purpose 
             FROM public.payment_orders 
             WHERE (provider_order_id = $1 OR id = $1) 
             FOR UPDATE;`,
            [razorOrderId],
          );

          if (poRes.rows.length > 0) {
            const po = poRes.rows[0];
            if (po.user_id !== userId) {
              throw new ApiError(
                403,
                "Payment order belongs to another user",
                "FORBIDDEN",
              );
            }
            if (po.status === "PAID") {
              throw new ApiError(
                400,
                "Payment order has already been processed",
                "ALREADY_PROCESSED",
              );
            }
            await client.query(
              `UPDATE public.payment_orders 
               SET status = 'PAID', paid_at = CURRENT_TIMESTAMP, provider_payment_id = $1, updated_at = CURRENT_TIMESTAMP 
               WHERE id = $2;`,
              [razorId, po.id],
            );
          }

          logger.info(
            `Player ${userId} joined game ${gameId} via Razorpay reference ${razorId}. Wallet balance unchanged.`,
          );

          paymentMethodRecorded = "RAZORPAY";
          paymentRefRecorded = razorId;
        }
      }

      const teamCountRes = await client.query(
        `SELECT team, COUNT(*) as count FROM public.game_players WHERE game_id = $1 GROUP BY team;`,
        [gameId],
      );
      let teamACount = 0;
      let teamBCount = 0;
      for (const row of teamCountRes.rows) {
        if (row.team === "TEAM_A") teamACount = parseInt(row.count, 10);
        if (row.team === "TEAM_B") teamBCount = parseInt(row.count, 10);
      }
      const assignedTeam = teamACount <= teamBCount ? "TEAM_A" : "TEAM_B";

      const insertRes = await client.query(
        `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method, payment_reference)
         VALUES ($1, $2, $3, $4, 'PAID', $5, $6)
         RETURNING id;`,
        [
          gameId,
          userId,
          assignedTeam,
          (position || "MID").toUpperCase(),
          paymentMethodRecorded,
          paymentRefRecorded,
        ],
      );
      rosterId = insertRes.rows[0]?.id;

      if (currentPlayersCount + 1 >= maxPlayers) {
        await client.query(
          `UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [gameId],
        );
      }

      await GamesRepository.addActivityLog(
        {
          gameId,
          actorId: userId,
          actorRoleName: "PLAYER",
          actionType: "PLAYER_JOINED",
          details: `Player joined ${assignedTeam} in position ${position}`,
        },
        client,
      );

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }

    if (newBalance !== null) {
      sendWalletUpdate(userId, { walletBalance: newBalance });
    }

    sendUserNotification(userId, {
      title: "⚽ Joined Match Successfully",
      message: `Position: ${position}. See you on the pitch!`,
      type: "SUCCESS",
    });

    // Notify managers when player joins & pays entry fee
    try {
      const playerRes = await dbPool.query(
        `SELECT name, phone FROM public.users WHERE id = $1;`,
        [userId],
      );
      const playerName = playerRes.rows[0]?.name || "Player";
      const entryFee = Number(game.entry_fee || 0);
      const formattedAmount = `₹${entryFee.toFixed(0)}`;
      const courtDisplayName =
        game.court_name || CourtsService.getCourtDisplayName(game.court_id);

      const mgrRes = await dbPool.query(
        `SELECT DISTINCT u.id as user_id
         FROM public.users u
         LEFT JOIN public.club_managers cm ON cm.user_id = u.id
         WHERE (u.role_id = 2 AND u.status = 'ACTIVE')
            OR (cm.club_id = $1 AND u.status = 'ACTIVE');`,
        [game.club_id || "smash_up_india_club"],
      );

      const notifTitle = "⚽ Player Joined Match";
      const notifBody = `Player "${playerName}" joined match "${game.title}" on ${courtDisplayName} (${game.match_date} ${game.start_time}). Paid Amount: ${formattedAmount}.`;

      for (const mgr of mgrRes.rows) {
        await NotificationService.createNotification({
          userId: mgr.user_id,
          title: notifTitle,
          body: notifBody,
          message: notifBody,
          type: "MATCH_JOINED",
          clubId: game.club_id || "smash_up_india_club",
          gameId,
          data: {
            gameId,
            playerName,
            userId,
            amountPaid: entryFee,
            formattedAmount,
            courtName: courtDisplayName,
            matchDate: game.match_date,
            startTime: game.start_time,
            route: "/manager/notifications",
          },
        });
      }

      const io = getSocketIO();
      if (io) {
        io.emit(SOCKET_EVENTS.MATCH_LIVE_FEED, {
          gameId,
          action: "PLAYER_JOINED",
          playerName,
          amountPaid: entryFee,
          formattedAmount,
        });
      }
    } catch (mgrErr: any) {
      logger.warn(
        `Failed to notify managers for player joining game ${gameId}: ${mgrErr.message}`,
      );
    }

    return {
      success: true,
      gameId,
      rosterId,
      newWalletBalance: newBalance,
    };
  }

  static async switchTeam(userId: string, gameId: string) {
    const res = await dbPool.query(
      `SELECT public.switch_player_team($1, $2) as new_team;`,
      [userId, gameId],
    );

    const newTeam = res.rows[0]?.new_team;
    sendUserNotification(userId, {
      title: "⚽ Switched Team",
      message: `You are now on ${newTeam}!`,
      type: "INFO",
    });

    return { gameId, newTeam };
  }

  static async leaveGame(userId: string, gameId: string) {
    const client = await dbPool.connect();
    let wasRefunded = false;
    let entryFee = 0;
    let newBal: number | null = null;

    try {
      await client.query("BEGIN");

      const gameRes = await client.query(
        `SELECT id, title, entry_fee, status FROM public.games WHERE id = $1 FOR UPDATE;`,
        [gameId],
      );
      if (gameRes.rows.length === 0) {
        throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
      }
      const game = gameRes.rows[0];

      const playerRes = await client.query(
        `SELECT id, payment_status, payment_method, payment_reference 
         FROM public.game_players 
         WHERE game_id = $1 AND user_id = $2 
         FOR UPDATE;`,
        [gameId, userId],
      );
      if (playerRes.rows.length === 0) {
        throw new ApiError(400, "Player is not in this game", "NOT_IN_GAME");
      }
      const playerRecord = playerRes.rows[0];

      entryFee = parseFloat(game.per_player_fee || "0.00");

      if (entryFee > 0 && playerRecord.payment_status === "PAID") {
        const refundRef = `LEAVE_REFUND:${gameId}:${userId}`;
        const existingRefund = await client.query(
          `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
          [userId, refundRef],
        );

        if (existingRefund.rows.length === 0) {
          const txRes = await client.query(
            `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
             VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
             RETURNING id, balance_after;`,
            [
              userId,
              entryFee,
              `Refund for leaving match "${game.title || "Pickle Match"}"`,
              refundRef,
            ],
          );
          newBal = parseFloat(txRes.rows[0]?.balance_after || "0.00");

          await client.query(
            `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
             VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
             ON CONFLICT (id) DO NOTHING;`,
            [
              txRes.rows[0]?.id,
              userId,
              entryFee,
              newBal,
              `Refund for leaving match "${game.title || "Pickle Match"}"`,
              refundRef,
            ],
          );
          wasRefunded = true;
        }
      }

      await client.query(
        `DELETE FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
        [gameId, userId],
      );

      if (game.status === "FULL") {
        await client.query(
          `UPDATE public.games SET status = 'OPEN_FOR_JOINING', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [gameId],
        );
      }

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }

    if (wasRefunded && newBal !== null) {
      sendWalletUpdate(userId, { walletBalance: newBal });
    }

    sendUserNotification(userId, {
      title: "⚽ Left Match",
      message: wasRefunded
        ? `You left the match. ₹${entryFee.toFixed(2)} refunded to your wallet.`
        : "You have left the match roster.",
      type: "INFO",
    });

    try {
      const nextReserve = await GamesRepository.popNextWaitlistPlayer(gameId);
      if (nextReserve) {
        await joinGameWithWallet(
          nextReserve.user_id,
          gameId,
          nextReserve.position || "MID",
        );
        sendUserNotification(nextReserve.user_id, {
          title: "🎉 Promoted from Waitlist!",
          message:
            "A spot opened up and you have been moved to the active roster!",
          type: "SUCCESS",
        });
        logger.info(
          `Promoted reserve player ${nextReserve.user_id} into game ${gameId}`,
        );
      }
    } catch (err) {
      logger.error(
        { err },
        `Error auto-promoting waitlist player for game ${gameId}`,
      );
    }

    return { success: true, gameId, refunded: wasRefunded };
  }

  static async getAuthorizedVideos(
    userId: string,
    gameId: string,
    userRole = 3,
  ) {
    try {
      await dbPool.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1 AND status NOT IN ('COMPLETED', 'CANCELLED')
           AND (match_date + end_time) <= CURRENT_TIMESTAMP;`,
        [gameId],
      );
    } catch (_) {}

    const game = await GamesRepository.getGameById(gameId);
    if (!game) throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");

    if (userRole === 3) {
      const isParticipant = await dbPool.query(
        `SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2
         UNION
         SELECT 1 FROM public.games WHERE id = $1 AND creator_id = $2;`,
        [gameId, userId],
      );
      if (isParticipant.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: Only active match participants can access video recordings",
          "FORBIDDEN_RECORDING_ACCESS",
        );
      }
    } else if (userRole === 2) {
      const isClubManager = await dbPool.query(
        `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
        [game.club_id, userId],
      );
      if (isClubManager.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You do not manage the club hosting this match",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
    }

    const videos = await GamesRepository.getGameVideos(gameId);
    const videoResults = [];

    for (let i = 0; i < videos.length; i++) {
      const vid = videos[i];
      try {
        const signedPlaybackUrl = await getSignedPlaybackUrl(
          vid.video_url,
          3600,
        );
        videoResults.push({
          videoId: vid.id,
          id: vid.id,
          cctvId: vid.cctv_id || null,
          cameraName: vid.camera_name || `Camera ${i + 1}`,
          cameraType: vid.camera_type || "RTSP_DOME",
          cameraStatus: vid.camera_status || "ONLINE",
          courtId: vid.court_id || null,
          courtName: vid.court_name || "Court 1",
          clubName: vid.club_name || "Smash Up India",
          title: vid.title,
          status: vid.status,
          durationSeconds: vid.duration_seconds || 5400,
          startedAt: vid.started_at || vid.created_at,
          endedAt: vid.actual_stopped_at || vid.created_at,
          playbackUrl: signedPlaybackUrl || vid.video_url || "",
        });
      } catch (err: any) {
        logger.warn(
          `Failed to sign playback URL for video ${vid.id}: ${err.message}`,
        );
      }
    }

    return videoResults;
  }

  static async cancelPlayerGame(
    userId: string,
    gameId: string,
    reason?: string,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      const gameRes = await client.query(
        `SELECT * FROM public.games WHERE id = $1 FOR UPDATE;`,
        [gameId],
      );
      if (gameRes.rows.length === 0) {
        throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
      }
      const game = gameRes.rows[0];

      if (game.creator_id !== userId) {
        throw new ApiError(
          403,
          "Only the host player who created this match can cancel it",
          "FORBIDDEN_NOT_HOST",
        );
      }

      if (game.status === "CANCELLED") {
        throw new ApiError(
          400,
          "Match is already cancelled",
          "ALREADY_CANCELLED",
        );
      }

      if (game.status === "COMPLETED" || game.status === "ONGOING") {
        throw new ApiError(
          400,
          "Cannot cancel an ongoing or completed match",
          "INVALID_MATCH_STATUS",
        );
      }

      let datePart = "";
      if (game.match_date instanceof Date) {
        const year = game.match_date.getFullYear();
        const month = String(game.match_date.getMonth() + 1).padStart(2, "0");
        const day = String(game.match_date.getDate()).padStart(2, "0");
        datePart = `${year}-${month}-${day}`;
      } else {
        datePart = String(game.match_date).slice(0, 10);
      }
      const timeStr =
        String(game.start_time).length === 5
          ? `${game.start_time}:00`
          : String(game.start_time);
      const parsedStartTime = new Date(`${datePart}T${timeStr}`);
      const matchStart = !isNaN(parsedStartTime.getTime())
        ? parsedStartTime
        : new Date();
      const now = new Date();

      if (now >= matchStart) {
        throw new ApiError(
          400,
          "Cannot cancel a match that has already started or passed. Please contact the turf club manager.",
          "MATCH_ALREADY_STARTED",
        );
      }

      const cancelReasonText =
        reason && reason.trim().length > 0
          ? `Cancelled by host player: ${reason.trim()}`
          : "Cancelled by host player";

      await client.query(
        `UPDATE public.games SET status = 'CANCELLED', cancellation_reason = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2;`,
        [cancelReasonText, gameId],
      );

      try {
        await client.query(
          `UPDATE public.cctv_recordings SET status = 'CANCELLED', recording_status = 'CANCELLED', actual_stopped_at = CURRENT_TIMESTAMP WHERE game_id = $1;`,
          [gameId],
        );
      } catch (_) {}

      const hostFee = parseFloat(game.entry_fee || "0.00");
      const perPlayerFee = parseFloat(game.per_player_fee || "0.00");
      const refundNotifications: Array<{
        userId: string;
        newBalance: number;
        refundAmount: number;
      }> = [];

      // 1. Refund Host ONLY if the host player actually paid (payment_status = 'PAID' and payment_method IN ('WALLET', 'RAZORPAY'))
      if (hostFee > 0 && game.creator_id) {
        const hostPlayerRes = await client.query(
          `SELECT payment_status, payment_method, payment_reference, refund_status 
           FROM public.game_players 
           WHERE game_id = $1 AND user_id = $2 FOR UPDATE;`,
          [gameId, game.creator_id],
        );
        const hostRecord = hostPlayerRes.rows[0];
        const hostMethod = (hostRecord?.payment_method || "").toUpperCase();
        const hostActuallyPaid = hostRecord
          ? hostRecord.payment_status === "PAID" &&
            (hostMethod === "WALLET" || hostMethod === "RAZORPAY")
          : true;

        if (
          hostActuallyPaid &&
          hostRecord?.refund_status !== "REFUNDED_TO_WALLET" &&
          hostRecord?.payment_status !== "REFUNDED"
        ) {
          const hostRefundRef = `MATCH_HOST_REFUND:${gameId}:${game.creator_id}`;
          const existingHostRefund = await client.query(
            `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
            [game.creator_id, hostRefundRef],
          );

          if (existingHostRefund.rows.length === 0) {
            const refundDesc =
              hostMethod === "RAZORPAY"
                ? `Pitch booking refund for cancelled match (originally paid via Razorpay): ${game.title || "Pickle Match"}`
                : `Pitch booking refund for cancelled match: ${game.title || "Pickle Match"}`;

            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [game.creator_id, hostFee, refundDesc, hostRefundRef],
            );
            const newBal = parseFloat(txRes.rows[0]?.balance_after || "0.00");

            await client.query(
              `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
               VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
               ON CONFLICT (id) DO NOTHING;`,
              [
                txRes.rows[0]?.id,
                game.creator_id,
                hostFee,
                newBal,
                refundDesc,
                hostRefundRef,
              ],
            );

            await client.query(
              `UPDATE public.game_players 
               SET payment_status = 'REFUNDED', refund_status = 'REFUNDED_TO_WALLET', refund_reference = $1, refund_amount = $2, refunded_at = CURRENT_TIMESTAMP 
               WHERE game_id = $3 AND user_id = $4;`,
              [hostRefundRef, hostFee, gameId, game.creator_id],
            );

            if (hostRecord?.payment_reference) {
              await client.query(
                `UPDATE public.payment_orders 
                 SET status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP 
                 WHERE (provider_payment_id = $1 OR provider_order_id = $1 OR id = $1) AND user_id = $2;`,
                [hostRecord.payment_reference, game.creator_id],
              );
            }

            refundNotifications.push({
              userId: game.creator_id,
              newBalance: newBal,
              refundAmount: hostFee,
            });
          }
        }
      }

      // 2. Refund ONLY non-host players who ACTUALLY paid (payment_status = 'PAID' and payment_method IN ('WALLET', 'RAZORPAY'))
      // Players who joined free (FREE) or were added by host (HOST_ADDED) or did not pay MUST NOT be refunded!
      if (perPlayerFee > 0) {
        const playersRes = await client.query(
          `SELECT user_id, payment_method, payment_reference, payment_status, refund_status 
           FROM public.game_players 
           WHERE game_id = $1 AND user_id != $2 AND payment_status = 'PAID' AND payment_method IN ('WALLET', 'RAZORPAY')
           FOR UPDATE;`,
          [gameId, game.creator_id],
        );

        for (const pRow of playersRes.rows) {
          const pUserId = pRow.user_id;
          const pMethod = (pRow.payment_method || "").toUpperCase();
          const pRef = pRow.payment_reference;

          if (
            pRow.refund_status === "REFUNDED_TO_WALLET" ||
            pRow.payment_status === "REFUNDED"
          ) {
            continue;
          }

          let refundAmount = 0;
          if (pMethod === "WALLET") {
            const txCheck = await client.query(
              `SELECT amount FROM public.transactions 
               WHERE user_id = $1 AND type = 'PAYMENT' AND reference_id = $2 AND status = 'SUCCESS' 
               ORDER BY created_at DESC LIMIT 1;`,
              [pUserId, gameId],
            );
            if (txCheck.rows.length > 0) {
              const amt = parseFloat(txCheck.rows[0].amount || "0.00");
              refundAmount = amt > 0 ? amt : 0;
            } else {
              refundAmount = 0;
            }
          } else if (pMethod === "RAZORPAY" && pRef) {
            const poCheck = await client.query(
              `SELECT amount_paise FROM public.payment_orders 
               WHERE (provider_payment_id = $1 OR provider_order_id = $1 OR id = $1) AND user_id = $2 AND status = 'PAID' 
               ORDER BY created_at DESC LIMIT 1;`,
              [pRef, pUserId],
            );
            if (poCheck.rows.length > 0) {
              const amt =
                parseFloat(poCheck.rows[0].amount_paise || "0") / 100.0;
              refundAmount = amt > 0 ? amt : 0;
            } else {
              refundAmount = 0;
            }
          } else {
            refundAmount = 0;
          }

          if (refundAmount <= 0) continue;

          const refundRef = `MATCH_REFUND:${gameId}:${pUserId}`;
          const existingRefund = await client.query(
            `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
            [pUserId, refundRef],
          );

          let newBal = 0;
          if (existingRefund.rows.length === 0) {
            const refundDesc =
              pMethod === "RAZORPAY"
                ? `Refund for cancelled match (originally paid via Razorpay): ${game.title || "Pickle Match"}`
                : `Refund for cancelled match: ${game.title || "Pickle Match"}`;

            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [pUserId, refundAmount, refundDesc, refundRef],
            );
            newBal = parseFloat(txRes.rows[0]?.balance_after || "0.00");

            await client.query(
              `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
               VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
               ON CONFLICT (id) DO NOTHING;`,
              [
                txRes.rows[0]?.id,
                pUserId,
                refundAmount,
                newBal,
                refundDesc,
                refundRef,
              ],
            );

            await client.query(
              `UPDATE public.game_players 
               SET payment_status = 'REFUNDED', refund_status = 'REFUNDED_TO_WALLET', refund_reference = $1, refund_amount = $2, refunded_at = CURRENT_TIMESTAMP 
               WHERE game_id = $3 AND user_id = $4;`,
              [refundRef, refundAmount, gameId, pUserId],
            );

            if (pRef) {
              await client.query(
                `UPDATE public.payment_orders 
                 SET status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP 
                 WHERE (provider_payment_id = $1 OR provider_order_id = $1 OR id = $1) AND user_id = $2;`,
                [pRef, pUserId],
              );
            }
          } else {
            const wRes = await client.query(
              `SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1;`,
              [pUserId],
            );
            newBal = parseFloat(wRes.rows[0]?.wallet_balance || "0.00");
          }

          refundNotifications.push({
            userId: pUserId,
            newBalance: newBal,
            refundAmount,
          });
        }
      }

      await client.query(
        `UPDATE public.game_slot_requests SET status = 'CANCELLED', payment_status = 'REFUNDED' WHERE game_id = $1;`,
        [gameId],
      );

      await GamesRepository.addActivityLog(
        {
          gameId,
          actorId: userId,
          actorRoleName: "PLAYER",
          actionType: "MATCH_CANCELLED",
          details: `Match cancelled by host player: ${cancelReasonText}`,
        },
        client,
      );

      try {
        const totalRefundedSum = refundNotifications.reduce(
          (acc, curr) => acc + curr.refundAmount,
          0,
        );
        const hostUserRes = await client.query(
          `SELECT name FROM public.users WHERE id = $1;`,
          [game.creator_id],
        );
        const hostName = hostUserRes.rows[0]?.name || "Host Player";

        const hostCancelDetails = `Match "${game.title || "Match"}" (ID: ${gameId}) scheduled for ${game.match_date ? String(game.match_date).slice(0, 10) : ""} at ${game.start_time || ""} was CANCELLED by Host Player "${hostName}". Host: ${hostName}. Amount: ₹${game.entry_fee || 0}. Total Refunded: ₹${totalRefundedSum.toFixed(2)}. Reason: ${cancelReasonText}`;

        await client.query(
          `INSERT INTO public.audit_logs (user_id, admin_name, action, target, details)
           VALUES ($1, $2, 'MATCH_CANCELLED', $3, $4);`,
          [userId, hostName, game.title || gameId, hostCancelDetails],
        );
      } catch (_) {}

      await client.query("COMMIT");

      try {
        const io = getSocketIO();
        io.emit("match:cancelled", {
          gameId,
          status: "CANCELLED",
          reason: cancelReasonText,
          cancelledBy: "HOST",
        });
      } catch (_) {}

      for (const item of refundNotifications) {
        if (item.refundAmount > 0) {
          sendWalletUpdate(item.userId, { walletBalance: item.newBalance });
          sendUserNotification(item.userId, {
            title: "⚠️ Match Cancelled by Host",
            message: `Host cancelled "${game.title}". ₹${item.refundAmount.toFixed(2)} refunded to your wallet.`,
            type: "WARNING",
          });
        }
      }

      return { gameId, status: "CANCELLED", reason: cancelReasonText };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  static async searchPlayersForRoster(
    gameIdOrQuery: string = "",
    queryStr?: string,
  ) {
    let effectiveGameId = "";
    let effectiveQuery = "";

    if (queryStr !== undefined) {
      effectiveGameId = (gameIdOrQuery || "").trim();
      effectiveQuery = (queryStr || "").trim();
    } else {
      effectiveQuery = (gameIdOrQuery || "").trim();
    }

    const conditions: string[] = [
      "(u.role_id = 3 OR u.role_id IS NULL OR u.role_id::text = '3')",
      "COALESCE(u.role_id, 3) NOT IN (1, 2)",
      "COALESCE(u.status::text, 'ACTIVE') = 'ACTIVE'",
      "u.status::text <> 'SUSPENDED'",
    ];
    const values: any[] = [];
    let idx = 1;

    // Exclude players who are ALREADY in the roster (Team A or Team B) or are the host for this match!
    if (effectiveGameId && effectiveGameId.length > 0) {
      conditions.push(
        `NOT EXISTS (
           SELECT 1 FROM public.game_players gp 
           WHERE gp.game_id = $${idx} AND gp.user_id = u.id
         )`,
      );
      conditions.push(
        `NOT EXISTS (
           SELECT 1 FROM public.games g 
           WHERE g.id = $${idx} AND g.creator_id = u.id
         )`,
      );
      values.push(effectiveGameId);
      idx++;
    }

    if (effectiveQuery && effectiveQuery.length > 0) {
      conditions.push(
        `(u.name ILIKE $${idx} OR u.phone ILIKE $${idx} OR u.email ILIKE $${idx})`,
      );
      values.push(`%${effectiveQuery}%`);
      idx++;
    }

    const query = `
      SELECT u.id, u.name, u.email, u.phone, u.profile_image_url, u.role_id
      FROM public.users u
      WHERE ${conditions.join(" AND ")}
      ORDER BY LOWER(u.name) ASC
      LIMIT 50;
    `;

    const res = await dbPool.query(query, values);
    return res.rows.map((row) => ({
      id: row.id,
      userId: row.id,
      name: row.name || row.email || "Player",
      email: row.email || "",
      phone: row.phone || "",
      profileImageUrl: row.profile_image_url || null,
      roleId: Number(row.role_id || 3),
    }));
  }

  static async addPlayerToRosterByHost(params: {
    hostUserId: string;
    gameId: string;
    targetUserId: string;
    team: string;
    position: string;
  }) {
    const { hostUserId, gameId, targetUserId, team, position } = params;

    const gameRes = await dbPool.query(
      `SELECT * FROM public.games WHERE id = $1;`,
      [gameId],
    );
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
    }
    const game = gameRes.rows[0];

    // Verify requesting user is host/creator
    if (game.creator_id !== hostUserId) {
      throw new ApiError(
        403,
        "Only the match host can add players to the roster",
        "NOT_HOST",
      );
    }

    // Verify match status
    const statusUpper = (game.status || "").toUpperCase();
    if (
      statusUpper === "COMPLETED" ||
      statusUpper === "CANCELLED" ||
      statusUpper === "ONGOING" ||
      statusUpper === "STARTED"
    ) {
      throw new ApiError(
        400,
        `Cannot add players to a match that is ${statusUpper}`,
        "MATCH_LOCKED",
      );
    }

    // Check team count limit (max 11 players per team side)
    const targetTeam = team === "TEAM_B" ? "TEAM_B" : "TEAM_A";
    const countRes = await dbPool.query(
      `SELECT COUNT(*) as team_count FROM public.game_players WHERE game_id = $1 AND team = $2 AND user_id <> $3;`,
      [gameId, targetTeam, targetUserId],
    );
    const currentTeamCount = parseInt(countRes.rows[0]?.team_count || "0", 10);
    if (currentTeamCount >= 11) {
      throw new ApiError(
        400,
        `${targetTeam === "TEAM_A" ? "Team A" : "Team B"} has already reached the maximum 11 player limit`,
        "TEAM_FULL",
      );
    }

    // Get target player details & role
    const targetUserRes = await dbPool.query(
      `SELECT name, phone, role_id FROM public.users WHERE id = $1;`,
      [targetUserId],
    );
    if (targetUserRes.rows.length === 0) {
      throw new ApiError(404, "Target player not found");
    }
    const targetUser = targetUserRes.rows[0];
    const targetRoleId = Number(targetUser.role_id || 3);

    // Strictly block Admins (role_id = 1) and Managers (role_id = 2)
    if (targetRoleId === 1 || targetRoleId === 2) {
      throw new ApiError(
        400,
        "Admins and Managers cannot be added to the match player roster",
        "INVALID_PLAYER_ROLE",
      );
    }
    const targetName = targetUser.name || "Player";

    // Insert or update in game_players
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method)
       VALUES ($1, $2, $3, $4, 'PAID', 'HOST_ADDED')
       ON CONFLICT (game_id, user_id) DO UPDATE
       SET team = EXCLUDED.team, position = EXCLUDED.position, payment_status = 'PAID';`,
      [gameId, targetUserId, targetTeam, position || "ST"],
    );

    // Notify target player
    sendUserNotification(targetUserId, {
      title: "⚽ Added to Match Roster",
      message: `Host added you to ${targetTeam === "TEAM_A" ? "Team A" : "Team B"} for match "${game.title}"!`,
      type: "SUCCESS",
    });

    // Notify managers
    try {
      const courtDisplayName =
        game.court_name || CourtsService.getCourtDisplayName(game.court_id);
      const mgrRes = await dbPool.query(
        `SELECT DISTINCT u.id as user_id
         FROM public.users u
         LEFT JOIN public.club_managers cm ON cm.user_id = u.id
         WHERE (u.role_id = 2 AND u.status = 'ACTIVE')
            OR (cm.club_id = $1 AND u.status = 'ACTIVE');`,
        [game.club_id || "smash_up_india_club"],
      );

      const notifTitle = "⚽ Player Added to Roster";
      const notifBody = `Player "${targetName}" was added to ${targetTeam === "TEAM_A" ? "Team A" : "Team B"} by host for match "${game.title}" on ${courtDisplayName}.`;

      for (const mgr of mgrRes.rows) {
        await NotificationService.createNotification({
          userId: mgr.user_id,
          title: notifTitle,
          body: notifBody,
          message: notifBody,
          type: "MATCH_JOINED",
          clubId: game.club_id || "smash_up_india_club",
          gameId,
          data: {
            gameId,
            playerName: targetName,
            userId: targetUserId,
            courtName: courtDisplayName,
            matchDate: game.match_date,
            startTime: game.start_time,
            team: targetTeam,
            route: "/manager/notifications",
          },
        });
      }
    } catch (mgrErr: any) {
      logger.warn(
        `Failed to notify managers for adding player ${targetUserId} to game ${gameId}: ${mgrErr.message}`,
      );
    }

    // Broadcast Socket.IO live feed
    const io = getSocketIO();
    if (io) {
      io.emit(SOCKET_EVENTS.MATCH_LIVE_FEED, {
        gameId,
        action: "ROSTER_UPDATED",
        targetUserId,
        playerName: targetName,
        team: targetTeam,
      });
    }

    return { success: true, gameId, targetUserId, team: targetTeam };
  }

  static async removePlayerFromRosterByHost(params: {
    hostUserId: string;
    gameId: string;
    targetUserId: string;
  }) {
    const { hostUserId, gameId, targetUserId } = params;

    const gameRes = await dbPool.query(
      `SELECT * FROM public.games WHERE id = $1;`,
      [gameId],
    );
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
    }
    const game = gameRes.rows[0];

    // Verify requesting user is host/creator
    if (game.creator_id !== hostUserId) {
      throw new ApiError(
        403,
        "Only the match host can remove players from the roster",
        "NOT_HOST",
      );
    }

    // PREVENT REMOVING THE MATCH HOST/CREATOR
    if (targetUserId === game.creator_id) {
      throw new ApiError(
        400,
        "The match creator/host cannot be removed from the roster",
        "CANNOT_REMOVE_HOST",
      );
    }

    // Verify match status
    const statusUpper = (game.status || "").toUpperCase();
    if (
      statusUpper === "COMPLETED" ||
      statusUpper === "CANCELLED" ||
      statusUpper === "ONGOING" ||
      statusUpper === "STARTED"
    ) {
      throw new ApiError(
        400,
        `Cannot remove players from a match that is ${statusUpper}`,
        "MATCH_LOCKED",
      );
    }

    // Delete from game_players
    await dbPool.query(
      `DELETE FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
      [gameId, targetUserId],
    );

    // Notify target player
    sendUserNotification(targetUserId, {
      title: "⚽ Removed from Match Roster",
      message: `Host removed you from match "${game.title}".`,
      type: "INFO",
    });

    // Broadcast Socket.IO live feed
    const io = getSocketIO();
    if (io) {
      io.emit(SOCKET_EVENTS.MATCH_LIVE_FEED, {
        gameId,
        action: "ROSTER_UPDATED",
        targetUserId,
      });
    }

    return { success: true, gameId, targetUserId };
  }
}
