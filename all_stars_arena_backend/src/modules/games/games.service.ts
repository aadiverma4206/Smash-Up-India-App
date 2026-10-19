import crypto from "crypto";
import { dbPool } from "../../config/db.config.js";
import { GamesRepository } from "./games.repository.js";
import { getSignedPlaybackUrl } from "../../services/storage.service.js";
import {
  joinGameWithWallet,
  verifyUserWalletPin,
} from "../../services/wallet.service.js";
import {
  sendUserNotification,
  sendWalletUpdate,
} from "../../services/realtime.service.js";
import { ApiError } from "../../utils/apiResponse.js";
import { logger } from "../../utils/logger.js";

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
      paymentMethod?: string;
      paymentReference?: string;
      walletPin?: string;
      paymentOrderId?: string;
      razorpayPaymentId?: string;
      razorpayOrderId?: string;
      razorpaySignature?: string;
    },
  ) {
    // 1. Validate Creator Account & Role
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

    // 2. Canonical Club & Court Resolution
    // Canonical Club is strictly all_stars_arena_club
    data.clubId = "all_stars_arena_club";

    // Normalize Court ID strictly to 'court_1' or 'court_2'
    const courtInput = (data.courtId || (data as any).courtName || "")
      .toString()
      .toLowerCase();
    data.courtId = courtInput.includes("2") ? "court_2" : "court_1";

    // Ensure court exists and is AVAILABLE in DB
    const courtRes = await dbPool.query(
      `SELECT id, name, club_id, status FROM public.courts WHERE id = $1;`,
      [data.courtId],
    );
    if (courtRes.rows.length === 0) {
      await dbPool.query(
        `INSERT INTO public.courts (id, club_id, name, environment, surface, base_price, status)
         VALUES ($1, 'all_stars_arena_club', $2, 'Outdoor', '3G Turf', 1200.00, 'AVAILABLE')
         ON CONFLICT (id) DO NOTHING;`,
        [data.courtId, data.courtId === "court_2" ? "Court 2" : "Court 1"],
      );
    }

    // 4. Validate Format & Players
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

    // 5. Validate Date & Time
    const matchStart = new Date(`${data.matchDate}T${data.startTime}`);
    const matchEnd = new Date(`${data.matchDate}T${data.endTime}`);
    const now = new Date();

    if (isNaN(matchStart.getTime()) || isNaN(matchEnd.getTime())) {
      throw new ApiError(400, "Invalid match date or time format");
    }

    if (matchStart < now) {
      throw new ApiError(
        400,
        "Match date and start time cannot be in the past",
      );
    }

    if (matchEnd <= matchStart) {
      throw new ApiError(400, "Match end time must be after start time");
    }

    // 6. Check Court Overlap
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

    // 7. Atomic Transaction: Game Creation + Auto Roster Entry for Player Creator
    const client = await dbPool.connect();
    let newGame: any = null;

    try {
      await client.query("BEGIN");

      // Overlap check with row locking inside transaction to prevent race conditions
      const overlapLock = await client.query(
        `SELECT id FROM public.games
         WHERE court_id = $1 AND match_date = $2 AND status <> 'CANCELLED'
           AND ((start_time <= $3 AND end_time > $3)
             OR (start_time < $4 AND end_time >= $4)
             OR (start_time >= $3 AND end_time <= $4))
         FOR UPDATE;`,
        [data.courtId, data.matchDate, data.startTime, data.endTime],
      );
      if (overlapLock.rows.length > 0) {
        throw new ApiError(
          409,
          "This court was just booked by another player for the selected time slot",
          "COURT_OCCUPIED",
        );
      }

      const targetGameId = "gam_" + crypto.randomBytes(8).toString("hex");

      // Create Game inside same database transaction
      // Creator does NOT pay any entry fee! (Rules 1 & 2)
      newGame = await GamesRepository.createGame(
        {
          id: targetGameId,
          title: data.title || "11v11 Football Showdown",
          clubId: data.clubId,
          courtId: data.courtId,
          creatorId: creatorUserId,
          creatorRoleName,
          createdByPlayer: isPlayerCreator,
          format: formatKey,
          maxPlayers,
          entryFee,
          skillRequirement: skillReq,
          privacy: (data.privacy || "PUBLIC").toUpperCase(),
          matchDate: data.matchDate,
          startTime: data.startTime,
          endTime: data.endTime,
          description: data.description,
        },
        client,
      );

      // Rule 1: If a Player creates a game, the creator becomes Player + Host and automatically participates!
      // Add Player Creator directly to game_players on Team A without charge!
      if (isPlayerCreator) {
        const initialPosition = ((data as any).position || "ST").toUpperCase();
        await client.query(
          `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
           VALUES ($1, $2, 'TEAM_A', $3, 'HOST_FREE')
           ON CONFLICT (game_id, user_id) DO NOTHING;`,
          [targetGameId, creatorUserId, initialPosition],
        );
      }
      // Rule 2: If a Manager creates a game, manager is Host ONLY and NOT added to game_players.

      // Add Activity Log in same transaction
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

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }

    sendUserNotification(creatorUserId, {
      title: "⚽ Game Created",
      message: `Your game "${newGame.title}" has been created!`,
      type: "SUCCESS",
    });

    // Notify Manager(s) whenever a Player hosts/creates a match on the turf
    if (isPlayerCreator) {
      try {
        const mgrRes = await dbPool.query(
          `SELECT DISTINCT u.id as user_id
           FROM public.users u
           LEFT JOIN public.club_managers cm ON cm.user_id = u.id
           WHERE (u.role_id = 2 AND u.status = 'ACTIVE')
              OR (cm.club_id = $1 AND u.status = 'ACTIVE');`,
          [newGame.club_id || "all_stars_arena_club"],
        );
        for (const mgr of mgrRes.rows) {
          sendUserNotification(mgr.user_id, {
            title: "⚽ New Player Match Hosted",
            message: `A player hosted match "${newGame.title}" on turf for ${newGame.match_date} (${newGame.start_time}).`,
            type: "INFO",
            data: { gameId: newGame.id, route: "/manager/notifications" },
          });
        }
      } catch (mgrErr: any) {
        logger.warn(
          `Failed to notify managers for player match ${newGame.id}: ${mgrErr.message}`,
        );
      }
    } else if (
      newGame.approval_status === "PENDING_APPROVAL" &&
      newGame.club_id
    ) {
      try {
        const mgrRes = await dbPool.query(
          `SELECT user_id FROM public.club_managers WHERE club_id = $1;`,
          [newGame.club_id],
        );
        for (const mgr of mgrRes.rows) {
          sendUserNotification(mgr.user_id, {
            title: "📋 New Match Awaiting Approval",
            message: `Match "${newGame.title}" created on turf requires manager approval.`,
            type: "WARNING",
            data: { gameId: newGame.id, route: "/manager/notifications" },
          });
        }
      } catch (mgrErr: any) {
        logger.warn(
          `Failed to notify managers for pending match ${newGame.id}: ${mgrErr.message}`,
        );
      }
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

    try {
      await client.query("BEGIN");

      // 1. Lock Game Row
      const gameRes = await client.query(
        `SELECT * FROM public.games WHERE id = $1 FOR UPDATE;`,
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

      if (game.approval_status && game.approval_status !== "APPROVED") {
        throw new ApiError(
          400,
          "Cannot join match that is pending manager approval or rejected",
          "MATCH_NOT_APPROVED",
        );
      }

      // Check joining user account status & ensure managers cannot join matches as players
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

      // 2. Prevent Duplicate Joins (Rule 4)
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

      // 3. Prevent Over-booking / Check Capacity (Rule 3 & Rule 4)
      const countRes = await client.query(
        `SELECT COUNT(*) as current_count FROM public.game_players WHERE game_id = $1;`,
        [gameId],
      );
      const currentPlayersCount = parseInt(
        countRes.rows[0]?.current_count || "0",
        10,
      );
      if (currentPlayersCount >= game.max_players) {
        throw new ApiError(
          400,
          "Match is already at full player capacity",
          "MATCH_FULL",
        );
      }

      // 4. Handle Payment for Joining Player (Rule 3)
      const entryFee = parseFloat(game.entry_fee || "0.00");
      const paymentMethod = paymentDetails?.paymentMethod || "WALLET";

      if (entryFee > 0) {
        if (paymentMethod === "WALLET") {
          // Verify Wallet PIN if set
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

          // Lock player details FOR UPDATE & deduct balance
          const walletRes = await client.query(
            `SELECT wallet_balance FROM public.player_details WHERE user_id = $1 FOR UPDATE;`,
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

          // Deduct via authoritative transactions ledger
          const txRes = await client.query(
            `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
             VALUES ($1, 'PAYMENT', $2, 0, 'SUCCESS', $3, $4)
             RETURNING id, balance_after;`,
            [
              userId,
              entryFee,
              `Entry fee for joining match "${game.title || "Football Match"}"`,
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
              `Entry fee for joining match "${game.title || "Football Match"}"`,
              gameId,
            ],
          );
        } else if (paymentMethod === "RAZORPAY") {
          // Record razorpay reference if supplied
          if (
            paymentDetails?.razorpayPaymentId ||
            paymentDetails?.razorpayOrderId
          ) {
            const razorId =
              paymentDetails.razorpayPaymentId ||
              paymentDetails.razorpayOrderId;
            logger.info(
              `Player ${userId} joined game ${gameId} via Razorpay reference ${razorId}`,
            );
          }
        }
      }

      // 5. Balance Teams (Team A vs Team B)
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

      // 6. Insert into game_players
      const insertRes = await client.query(
        `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
         VALUES ($1, $2, $3, $4, 'PAID')
         RETURNING id;`,
        [gameId, userId, assignedTeam, (position || "MID").toUpperCase()],
      );
      rosterId = insertRes.rows[0]?.id;

      // 7. Update game status to FULL if max capacity reached
      if (currentPlayersCount + 1 >= game.max_players) {
        await client.query(
          `UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [gameId],
        );
      }

      // 8. Log Activity
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
    const left = await GamesRepository.leaveGame(gameId, userId);
    if (!left) {
      throw new ApiError(400, "Player is not in this game", "NOT_IN_GAME");
    }

    sendUserNotification(userId, {
      title: "⚽ Left Match",
      message: "You have left the match roster.",
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

    return { success: true, gameId };
  }

  static async getAuthorizedVideos(
    userId: string,
    gameId: string,
    userRole = 3,
  ) {
    const game = await GamesRepository.getGameById(gameId);
    if (!game) throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");

    // If role is PLAYER (role_id = 3), verify active participant in game_players
    if (userRole === 3) {
      const isParticipant = await dbPool.query(
        `SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
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
      // Manager role check
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
      const signedPlaybackUrl = await getSignedPlaybackUrl(vid.video_url, 3600);
      videoResults.push({
        videoId: vid.id,
        id: vid.id,
        cctvId: vid.cctv_id || null,
        cameraName: vid.camera_name || `Camera ${i + 1}`,
        cameraType: vid.camera_type || "RTSP_DOME",
        cameraStatus: vid.camera_status || "ONLINE",
        courtId: vid.court_id || null,
        courtName: vid.court_name || "Court 1",
        clubName: vid.club_name || "All Stars Turf",
        title: vid.title,
        status: vid.status,
        durationSeconds: vid.duration_seconds || 5400,
        startedAt: vid.started_at || vid.created_at,
        endedAt: vid.actual_stopped_at || vid.created_at,
        playbackUrl: signedPlaybackUrl,
      });
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

      // Check match start time: Cannot cancel once start time has arrived or passed!
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

      await client.query(
        `UPDATE public.games SET status = 'CANCELLED', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
        [gameId],
      );

      // Cancel any CCTV recording associated with this game
      try {
        await client.query(
          `UPDATE public.cctv_recordings SET status = 'CANCELLED', recording_status = 'CANCELLED', actual_stopped_at = CURRENT_TIMESTAMP WHERE game_id = $1;`,
          [gameId],
        );
      } catch (_) {}

      // Refund all successfully paid players with idempotency via immutable ledger (excluding free host)
      const entryFee = parseFloat(game.entry_fee || "0.00");
      const playersRes = await client.query(
        `SELECT user_id FROM public.game_players WHERE game_id = $1 AND payment_status = 'PAID' AND user_id != $2;`,
        [gameId, game.creator_id],
      );

      const refundNotifications: Array<{ userId: string; newBalance: number }> =
        [];

      for (const pRow of playersRes.rows) {
        const pUserId = pRow.user_id;
        if (entryFee > 0) {
          const refundRef = `MATCH_REFUND:${gameId}:${pUserId}`;

          // Check if already refunded to prevent duplicate refund
          const existingRefund = await client.query(
            `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
            [pUserId, refundRef],
          );

          let newBal = 0;
          if (existingRefund.rows.length === 0) {
            // Record in authoritative ledger (trg_apply_transaction credits player_details.wallet_balance safely)
            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [
                pUserId,
                entryFee,
                `Refund for cancelled match: ${game.title || "Football Match"}`,
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
                pUserId,
                entryFee,
                newBal,
                `Refund for cancelled match: ${game.title || "Football Match"}`,
                refundRef,
              ],
            );

            await client.query(
              `UPDATE public.game_players SET payment_status = 'REFUNDED' WHERE game_id = $1 AND user_id = $2;`,
              [gameId, pUserId],
            );
          } else {
            const wRes = await client.query(
              `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
              [pUserId],
            );
            newBal = parseFloat(wRes.rows[0]?.wallet_balance || "0.00");
          }

          refundNotifications.push({ userId: pUserId, newBalance: newBal });
        }
      }

      await client.query(
        `UPDATE public.game_slot_requests SET status = 'CANCELLED', payment_status = 'REFUNDED' WHERE game_id = $1;`,
        [gameId],
      );

      const cancelReasonText =
        reason && reason.trim() ? reason.trim() : "Cancelled by host player";
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

      await client.query("COMMIT");

      // Emit notifications after successful database commit
      for (const item of refundNotifications) {
        sendWalletUpdate(item.userId, { walletBalance: item.newBalance });
        sendUserNotification(item.userId, {
          title: "⚠️ Match Cancelled by Host",
          message: `Host cancelled "${game.title}". ${entryFee > 0 ? `₹${entryFee.toFixed(2)} refunded to your wallet.` : ""}`,
          type: "WARNING",
        });
      }

      return { gameId, status: "CANCELLED", reason: cancelReasonText };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }
}
