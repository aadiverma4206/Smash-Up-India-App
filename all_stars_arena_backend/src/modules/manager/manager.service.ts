import { ManagerRepository } from "./manager.repository.js";
import { CctvService } from "../cctv/cctv.service.js";
import { CctvRepository } from "../cctv/cctv.repository.js";
import { CctvRecordingService } from "../../services/cctvRecording.service.js";
import { GamesRepository } from "../games/games.repository.js";
import { updateLiveMatchScore } from "../../services/match.service.js";
import { getSignedPlaybackUrl } from "../../services/storage.service.js";
import {
  sendUserNotification,
  sendWalletUpdate,
} from "../../services/realtime.service.js";
import { dbPool } from "../../config/db.config.js";
import { ApiError } from "../../utils/apiResponse.js";
import { logger } from "../../utils/logger.js";

export class ManagerService {
  static async getDashboard(userId: string) {
    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) {
      throw new ApiError(
        404,
        "No assigned club found for this manager",
        "NO_CLUB_ASSIGNED",
      );
    }

    const stats = await ManagerRepository.getDashboardStats(club.id);
    const courts = await ManagerRepository.getCourtsByClub(club.id);
    const pendingGames = await ManagerRepository.getPendingPlayerGames(club.id);

    const totalRevenue = Number(stats.totalRevenueRupees || 0);
    const totalBookings = Number(stats.totalBookings || 0);
    const activeMatches = Number(stats.totalGames || 0);
    const onlineCctvCount = Number(stats.cctvStats?.onlineCameras || 0);
    const occupancyRatePercentage = 0.0;

    return {
      club,
      totalRevenue,
      totalRevenueRupees: totalRevenue,
      totalBookings,
      activeMatches,
      occupancyRatePercentage,
      onlineCctvCount,
      stats: {
        ...stats,
        pendingGamesCount: pendingGames.length,
      },
      courts,
    };
  }

  static async getClubCourts(userId: string) {
    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) {
      throw new ApiError(
        404,
        "No assigned club found for this manager",
        "NO_CLUB_ASSIGNED",
      );
    }
    return await ManagerRepository.getCourtsByClub(club.id);
  }

  static async getCourtSlots(
    userId: string,
    courtId: string,
    dateStr?: string,
  ) {
    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) {
      throw new ApiError(
        404,
        "No assigned club found for this manager",
        "NO_CLUB_ASSIGNED",
      );
    }

    const normalizedCourtId =
      courtId && courtId.includes("2") ? "court_2" : "court_1";
    courtId = normalizedCourtId;
    let court = await ManagerRepository.getCourtById(normalizedCourtId);

    if (!court) {
      throw new ApiError(404, "Court pitch not found", "COURT_NOT_FOUND");
    }

    const queryDate =
      dateStr && /^\d{4}-\d{2}-\d{2}$/.test(dateStr) ? dateStr : null;
    const games = await ManagerRepository.getCourtSlots(courtId, queryDate);

    return {
      court: {
        id: court.id,
        name: court.name,
        surface: court.surface,
        environment: court.environment,
        basePrice: parseFloat(court.base_price || "0"),
        status: court.status,
      },
      date: queryDate || "ALL",
      totalGames: games.length,
      slots: games,
    };
  }

  static async getPendingPlayerGames(userId: string) {
    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) {
      throw new ApiError(
        404,
        "No assigned club found for this manager",
        "NO_CLUB_ASSIGNED",
      );
    }
    return await ManagerRepository.getPendingPlayerGames(club.id);
  }

  static async approvePlayerGame(
    managerUserId: string,
    managerName: string,
    gameId: string,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      const gameRes = await client.query(
        `SELECT g.*
         FROM public.games g
         JOIN public.club_managers cm ON cm.club_id = g.club_id
         WHERE g.id = $1 AND cm.user_id = $2
         FOR UPDATE;`,
        [gameId, managerUserId],
      );

      if (gameRes.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You are not authorized to manage this match or match does not exist",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
      const game = gameRes.rows[0];

      if (game.approval_status === "APPROVED") {
        throw new ApiError(
          400,
          "Match is already approved",
          "ALREADY_APPROVED",
        );
      }

      if (game.approval_status === "REJECTED" || game.status === "CANCELLED") {
        throw new ApiError(
          400,
          "Cannot approve a cancelled or rejected match",
          "INVALID_MATCH_STATUS",
        );
      }

      // Check slot conflict on the same court
      const conflictRes = await client.query(
        `SELECT id FROM public.games
         WHERE court_id = $1 AND match_date = $2 AND status <> 'CANCELLED' AND approval_status = 'APPROVED' AND id <> $3
           AND ((start_time <= $4 AND end_time > $4)
             OR (start_time < $5 AND end_time >= $5)
             OR (start_time >= $4 AND end_time <= $5));`,
        [
          game.court_id,
          game.match_date,
          gameId,
          game.start_time,
          game.end_time,
        ],
      );
      if (conflictRes.rows.length > 0) {
        throw new ApiError(
          409,
          "Another approved game is already scheduled in this time slot on this court",
          "COURT_SLOT_CONFLICT",
        );
      }

      await client.query(
        `UPDATE public.games
         SET approval_status = 'APPROVED', manager_id = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2;`,
        [managerUserId, gameId],
      );

      await GamesRepository.addActivityLog(
        {
          gameId,
          actorId: managerUserId,
          actorName: managerName,
          actorRoleName: "MANAGER",
          actionType: "MATCH_APPROVED",
          details: `Manager approved match: ${game.title}`,
        },
        client,
      );

      await client.query("COMMIT");

      sendUserNotification(game.creator_id, {
        title: "🎉 Match Accepted!",
        message: `Your match "${game.title}" on ${game.match_date} has been accepted by the club manager!`,
        type: "SUCCESS",
      });

      return {
        gameId,
        status: game.status,
        approvalStatus: "APPROVED",
        message: "Match Accepted",
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  static async rejectPlayerGame(
    managerUserId: string,
    managerName: string,
    gameId: string,
    rejectionReason?: string,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      const gameRes = await client.query(
        `SELECT g.*
         FROM public.games g
         JOIN public.club_managers cm ON cm.club_id = g.club_id
         WHERE g.id = $1 AND cm.user_id = $2
         FOR UPDATE;`,
        [gameId, managerUserId],
      );

      if (gameRes.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You are not authorized to manage this match or match does not exist",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
      const game = gameRes.rows[0];

      if (game.approval_status === "REJECTED" || game.status === "CANCELLED") {
        throw new ApiError(
          400,
          "Match is already cancelled or rejected",
          "ALREADY_CANCELLED",
        );
      }

      const reasonText =
        rejectionReason && rejectionReason.trim().length > 0
          ? rejectionReason.trim()
          : "Declined by club manager";

      await client.query(
        `UPDATE public.games
         SET approval_status = 'REJECTED', status = 'CANCELLED', rejection_reason = $1, manager_id = $2, updated_at = CURRENT_TIMESTAMP
         WHERE id = $3;`,
        [reasonText, managerUserId, gameId],
      );

      // Refund paying players
      const entryFee = parseFloat(game.entry_fee || "0.00");
      const playersRes = await client.query(
        `SELECT user_id FROM public.game_players WHERE game_id = $1 AND payment_status = 'PAID';`,
        [gameId],
      );

      const refundNotifications: Array<{ userId: string; newBalance: number }> =
        [];

      for (const pRow of playersRes.rows) {
        const pUserId = pRow.user_id;
        if (entryFee > 0) {
          const refundRef = `MATCH_REFUND:${gameId}:${pUserId}`;
          const existingRefund = await client.query(
            `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
            [pUserId, refundRef],
          );

          let newBal = 0;
          if (existingRefund.rows.length === 0) {
            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [
                pUserId,
                entryFee,
                `Refund for match declined by manager: ${game.title || "Football Match"}`,
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
                `Refund for match declined by manager: ${game.title || "Football Match"}`,
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

      await GamesRepository.addActivityLog(
        {
          gameId,
          actorId: managerUserId,
          actorName: managerName,
          actorRoleName: "MANAGER",
          actionType: "MATCH_REJECTED",
          details: `Manager rejected match: ${reasonText}`,
        },
        client,
      );

      await client.query("COMMIT");

      sendUserNotification(game.creator_id, {
        title: "❌ Match Request Declined",
        message: `Your match request for "${game.title}" was declined: ${reasonText}`,
        type: "WARNING",
      });

      for (const item of refundNotifications) {
        sendWalletUpdate(item.userId, { walletBalance: item.newBalance });
        sendUserNotification(item.userId, {
          title: "⚠️ Match Cancelled",
          message: `Match "${game.title}" was declined. ₹${entryFee.toFixed(2)} refunded to your wallet.`,
          type: "WARNING",
        });
      }

      return {
        gameId,
        status: "CANCELLED",
        approvalStatus: "REJECTED",
        rejectionReason: reasonText,
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Approve Player Slot Request (Atomic DB Transaction)
   */
  static async approveSlotRequest(
    managerUserId: string,
    managerName: string,
    requestId: string,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      // Lock request row
      const reqRes = await client.query(
        `SELECT * FROM public.game_slot_requests WHERE id = $1 FOR UPDATE;`,
        [requestId],
      );
      if (reqRes.rows.length === 0) {
        throw new ApiError(404, "Slot request not found", "REQUEST_NOT_FOUND");
      }
      const slotReq = reqRes.rows[0];

      if (slotReq.status === "APPROVED") {
        throw new ApiError(
          400,
          "Slot request has already been approved",
          "ALREADY_APPROVED",
        );
      }

      // Lock game & verify manager club scope
      const gameRes = await client.query(
        `SELECT g.*
         FROM public.games g
         JOIN public.club_managers cm ON cm.club_id = g.club_id
         WHERE g.id = $1 AND cm.user_id = $2
         FOR UPDATE;`,
        [slotReq.game_id, managerUserId],
      );

      if (gameRes.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You are not authorized to manage this match or match does not exist",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
      const game = gameRes.rows[0];

      // Fetch player name
      const userRes = await client.query(
        `SELECT name FROM public.users WHERE id = $1;`,
        [slotReq.user_id],
      );
      const playerName = userRes.rows[0]?.name || "Player";

      if (game.status === "CANCELLED" || game.status === "COMPLETED") {
        throw new ApiError(
          400,
          `Cannot approve request for a match that is ${game.status}`,
          "INVALID_MATCH_STATUS",
        );
      }

      // Check current roster count
      const rosterCountRes = await client.query(
        `SELECT COUNT(*) as roster_count FROM public.game_players WHERE game_id = $1;`,
        [game.id],
      );
      const currentRosterCount = parseInt(
        rosterCountRes.rows[0]?.roster_count || "0",
        10,
      );

      if (currentRosterCount >= game.max_players) {
        throw new ApiError(
          400,
          "Match is already at full player capacity",
          "MATCH_FULL",
        );
      }

      // Check duplicate joined
      const dupCheck = await client.query(
        `SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
        [game.id, slotReq.user_id],
      );
      if (dupCheck.rows.length > 0) {
        throw new ApiError(
          400,
          "Player is already joined in active roster",
          "ALREADY_JOINED",
        );
      }

      // Process payment if entry fee > 0
      const entryFee = parseFloat(game.entry_fee || "0.00");
      if (entryFee > 0 && slotReq.payment_status !== "PAID") {
        // Lock player details wallet balance
        const walletRes = await client.query(
          `SELECT wallet_balance FROM public.player_details WHERE user_id = $1 FOR UPDATE;`,
          [slotReq.user_id],
        );
        const currentBalance = parseFloat(
          walletRes.rows[0]?.wallet_balance || "0.00",
        );

        if (currentBalance < entryFee) {
          throw new ApiError(
            400,
            `Player has insufficient wallet balance (Balance: ₹${currentBalance.toFixed(2)}, Fee: ₹${entryFee.toFixed(2)})`,
            "INSUFFICIENT_FUNDS",
          );
        }

        // Record DEBIT in authoritative transactions ledger (trg_apply_transaction validates and updates player_details.wallet_balance securely)
        const txRes = await client.query(
          `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
           VALUES ($1, 'PAYMENT', $2, 0, 'SUCCESS', $3, $4)
           RETURNING id, balance_after;`,
          [
            slotReq.user_id,
            entryFee,
            `Slot request payment approved for match: ${game.title || "Football Match"}`,
            game.id,
          ],
        );
        const newBalance = parseFloat(txRes.rows[0]?.balance_after || "0.00");

        await client.query(
          `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
           VALUES ($1, $2, 'DEBIT', $3, $4, $5, 'SUCCESS', $6)
           ON CONFLICT (id) DO NOTHING;`,
          [
            txRes.rows[0]?.id,
            slotReq.user_id,
            entryFee,
            newBalance,
            `Slot request payment approved for match: ${game.title || "Football Match"}`,
            game.id,
          ],
        );

        sendWalletUpdate(slotReq.user_id, { walletBalance: newBalance });
      }

      // Assign team based on current counts
      const teamCountRes = await client.query(
        `SELECT team, COUNT(*) as count FROM public.game_players WHERE game_id = $1 GROUP BY team;`,
        [game.id],
      );
      let teamACount = 0;
      let teamBCount = 0;
      for (const row of teamCountRes.rows) {
        if (row.team === "TEAM_A") teamACount = parseInt(row.count, 10);
        if (row.team === "TEAM_B") teamBCount = parseInt(row.count, 10);
      }
      const assignedTeam = teamACount <= teamBCount ? "TEAM_A" : "TEAM_B";

      // Insert into game_players
      await client.query(
        `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
         VALUES ($1, $2, $3, $4, 'PAID');`,
        [game.id, slotReq.user_id, assignedTeam, slotReq.position],
      );

      // Update slot request status
      await client.query(
        `UPDATE public.game_slot_requests SET status = 'APPROVED', payment_status = 'PAID', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
        [requestId],
      );

      // Update game status to FULL if max players reached
      if (currentRosterCount + 1 >= game.max_players) {
        await client.query(
          `UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [game.id],
        );
      }

      // Log activity
      await GamesRepository.addActivityLog(
        {
          gameId: game.id,
          actorId: managerUserId,
          actorName: managerName,
          actorRoleName: "MANAGER",
          actionType: "SLOT_APPROVED",
          details: `Manager approved ${playerName} for ${assignedTeam} in position ${slotReq.position}`,
        },
        client,
      );

      await client.query("COMMIT");

      // Send Realtime Notification
      sendUserNotification(slotReq.user_id, {
        title: "🎉 Slot Request Approved!",
        message: `Your request to join "${game.title}" was approved for ${assignedTeam}!`,
        type: "SUCCESS",
      });

      return {
        requestId,
        gameId: game.id,
        userId: slotReq.user_id,
        status: "APPROVED",
        team: assignedTeam,
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Reject Player Slot Request (Atomic DB Transaction)
   */
  static async rejectSlotRequest(
    managerUserId: string,
    managerName: string,
    requestId: string,
    rejectionReason: string,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      const reqRes = await client.query(
        `SELECT * FROM public.game_slot_requests WHERE id = $1 FOR UPDATE;`,
        [requestId],
      );
      if (reqRes.rows.length === 0) {
        throw new ApiError(404, "Slot request not found", "REQUEST_NOT_FOUND");
      }
      const slotReq = reqRes.rows[0];

      // Lock game & verify manager club scope
      const gameRes = await client.query(
        `SELECT g.*
         FROM public.games g
         JOIN public.club_managers cm ON cm.club_id = g.club_id
         WHERE g.id = $1 AND cm.user_id = $2
         FOR UPDATE;`,
        [slotReq.game_id, managerUserId],
      );

      if (gameRes.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You are not authorized to manage this match",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
      const game = gameRes.rows[0];

      const userRes = await client.query(
        `SELECT name FROM public.users WHERE id = $1;`,
        [slotReq.user_id],
      );
      const playerName = userRes.rows[0]?.name || "Player";

      // If player was in active game_players, remove them
      await client.query(
        `DELETE FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
        [game.id, slotReq.user_id],
      );

      // Refund payment if entry fee was paid via authoritative transactions ledger
      const entryFee = parseFloat(
        slotReq.entry_fee || game.entry_fee || "0.00",
      );
      let newBalance = 0;
      if (entryFee > 0 && slotReq.payment_status === "PAID") {
        const refundRef = `SLOT_REQUEST_REFUND:${requestId}:${slotReq.user_id}`;
        const existingRefund = await client.query(
          `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
          [slotReq.user_id, refundRef],
        );

        if (existingRefund.rows.length === 0) {
          const txRes = await client.query(
            `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
             VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
             RETURNING id, balance_after;`,
            [
              slotReq.user_id,
              entryFee,
              `Refund for declined slot request in match: ${game.title || "Football Match"}`,
              refundRef,
            ],
          );
          newBalance = parseFloat(txRes.rows[0]?.balance_after || "0.00");

          await client.query(
            `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
             VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
             ON CONFLICT (id) DO NOTHING;`,
            [
              txRes.rows[0]?.id,
              slotReq.user_id,
              entryFee,
              newBalance,
              `Refund for declined slot request in match: ${game.title || "Football Match"}`,
              refundRef,
            ],
          );
        } else {
          const wRes = await client.query(
            `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
            [slotReq.user_id],
          );
          newBalance = parseFloat(wRes.rows[0]?.wallet_balance || "0.00");
        }
      }

      // Update slot request to REJECTED
      const reasonText =
        rejectionReason && rejectionReason.trim().length > 0
          ? rejectionReason.trim()
          : "Slot request declined by manager";
      await client.query(
        `UPDATE public.game_slot_requests
         SET status = 'REJECTED', rejection_reason = $1, payment_status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP
         WHERE id = $2;`,
        [reasonText, requestId],
      );

      // Log activity
      await GamesRepository.addActivityLog(
        {
          gameId: game.id,
          actorId: managerUserId,
          actorName: managerName,
          actorRoleName: "MANAGER",
          actionType: "SLOT_REJECTED",
          details: `Manager rejected slot request for ${playerName}: ${reasonText}`,
        },
        client,
      );

      await client.query("COMMIT");

      if (newBalance > 0) {
        sendWalletUpdate(slotReq.user_id, { walletBalance: newBalance });
      }

      // Send Realtime Notification to player
      sendUserNotification(slotReq.user_id, {
        title: "❌ Slot Request Declined",
        message: `Your request for "${game.title}" was declined: ${reasonText}`,
        type: "WARNING",
      });

      return {
        requestId,
        gameId: game.id,
        userId: slotReq.user_id,
        status: "REJECTED",
        rejectionReason: reasonText,
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Cancel Match & Process Atomic Refunds
   */
  static async cancelMatchWithRefunds(
    managerUserId: string,
    managerName: string,
    gameId: string,
    cancellationReason = "Cancelled by club manager",
    userRole = 2,
  ) {
    const client = await dbPool.connect();
    try {
      await client.query("BEGIN");

      // Lock game & verify scope
      let gameQuery = "";
      let queryParams: any[] = [];

      if (userRole === 1) {
        // Admin has global authority across all clubs
        gameQuery = `SELECT g.* FROM public.games g WHERE g.id = $1 FOR UPDATE;`;
        queryParams = [gameId];
      } else {
        // Manager must manage the hosting club
        gameQuery = `SELECT g.*
         FROM public.games g
         JOIN public.club_managers cm ON cm.club_id = g.club_id
         WHERE g.id = $1 AND cm.user_id = $2
         FOR UPDATE;`;
        queryParams = [gameId, managerUserId];
      }

      const gameRes = await client.query(gameQuery, queryParams);
      if (gameRes.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You are not authorized to cancel this match",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
      const game = gameRes.rows[0];

      if (game.status === "CANCELLED") {
        throw new ApiError(
          400,
          "Match is already cancelled",
          "ALREADY_CANCELLED",
        );
      }

      if (game.status === "COMPLETED") {
        throw new ApiError(
          400,
          "Cannot cancel a completed match",
          "INVALID_MATCH_STATUS",
        );
      }

      // Set status = CANCELLED
      await client.query(
        `UPDATE public.games SET status = 'CANCELLED', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
        [gameId],
      );

      // Stop CCTV recording if active
      let activeRecordingId: string | null = null;
      try {
        const recRes = await client.query(
          `SELECT id FROM public.cctv_recordings WHERE game_id = $1 AND (status = 'RECORDING' OR recording_status = 'RECORDING');`,
          [gameId],
        );
        if (recRes.rows.length > 0) {
          activeRecordingId = recRes.rows[0].id;
          await client.query(
            `UPDATE public.cctv_recordings SET status = 'CANCELLED', recording_status = 'CANCELLED', actual_stopped_at = CURRENT_TIMESTAMP WHERE id = $1;`,
            [activeRecordingId],
          );
        }
      } catch (_) {}

      // Process Refunds for all joined players
      const entryFee = parseFloat(game.entry_fee || "0.00");
      const playersRes = await client.query(
        `SELECT user_id FROM public.game_players WHERE game_id = $1 AND payment_status = 'PAID';`,
        [gameId],
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
                `Refund for match cancelled by ${userRole === 1 ? "admin" : "manager"}: ${game.title || "Football Match"}`,
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
                `Refund for match cancelled by ${userRole === 1 ? "admin" : "manager"}: ${game.title || "Football Match"}`,
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

      // Update requests & waitlist
      await client.query(
        `UPDATE public.game_slot_requests SET status = 'CANCELLED', payment_status = 'REFUNDED' WHERE game_id = $1;`,
        [gameId],
      );

      // Log activity & audit entry
      await GamesRepository.addActivityLog(
        {
          gameId,
          actorId: managerUserId,
          actorName: managerName,
          actorRoleName: userRole === 1 ? "ADMIN" : "MANAGER",
          actionType: "MATCH_CANCELLED",
          details: `Match cancelled by ${userRole === 1 ? "admin" : "manager"} ${managerName}: ${cancellationReason}`,
        },
        client,
      );

      await client.query(
        `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
         VALUES ($1, $2, 'MATCH_CANCELLED', $3, $4);`,
        [managerUserId, managerName, gameId, cancellationReason],
      );

      if (refundNotifications.length > 0) {
        await client.query(
          `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
           VALUES ($1, $2, 'WALLET_REFUND_PROCESSED', $3, $4);`,
          [
            managerUserId,
            managerName,
            gameId,
            `Refunds credited to ${refundNotifications.length} player wallets for cancelled match "${game.title || gameId}" (Reason: ${cancellationReason})`,
          ],
        );
      }

      await client.query("COMMIT");

      if (activeRecordingId) {
        try {
          await CctvRecordingService.stopRecording(activeRecordingId, {
            userId: managerUserId,
            reason: `MATCH_CANCELLED: ${cancellationReason}`,
            manualStop: true,
          });
        } catch (_) {}
      }

      // Emit notifications after successful database commit
      for (const item of refundNotifications) {
        sendWalletUpdate(item.userId, { walletBalance: item.newBalance });
        sendUserNotification(item.userId, {
          title: "⚠️ Match Cancelled",
          message: `"${game.title}" was cancelled by ${userRole === 1 ? "admin" : "manager"}. ${entryFee > 0 ? `₹${entryFee.toFixed(2)} refunded to your wallet.` : ""}`,
          type: "WARNING",
        });
      }

      return { gameId, status: "CANCELLED", cancellationReason };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Start Match (Dynamic start_time = NOW, end_time = NOW + 1.5h) & Trigger CCTV Recording
   */
  static async startMatch(
    managerId: string,
    managerName: string,
    gameId: string,
  ) {
    const gameRes = await dbPool.query(
      "SELECT * FROM public.games WHERE id = $1;",
      [gameId],
    );
    if (gameRes.rows.length === 0)
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");

    // Dynamic start_time = current time, match_date = today, end_time = start_time + 1.5 hours (90 mins)
    const updatedGame = await ManagerRepository.startMatchGame(gameId);

    // Trigger CCTV Recording Asynchronously & update camera status
    try {
      const cameras = await CctvRepository.getCamerasByClub(
        gameRes.rows[0].club_id,
      );
      const courtCamera = cameras.find(
        (c) => c.court_id === gameRes.rows[0].court_id && c.is_enabled,
      );

      if (courtCamera) {
        await dbPool.query(
          `UPDATE public.cctv_cameras SET status = 'RECORDING', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [courtCamera.id],
        );

        CctvService.startMatchRecording(
          managerId,
          managerName,
          gameId,
          courtCamera.id,
        ).catch((err) => {
          logger.error({ err }, `Async CCTV start failed for Game ${gameId}`);
        });
      }
    } catch (cctvErr) {
      logger.error(
        { cctvErr },
        `CCTV Recording setup failed for Game ${gameId}`,
      );
    }

    await GamesRepository.addActivityLog({
      gameId,
      actorId: managerId,
      actorName: managerName,
      actorRoleName: "MANAGER",
      actionType: "MATCH_STARTED",
      details: `Match started dynamically at ${updatedGame.start_time || "current time"}. Scheduled end: ${updatedGame.end_time || "+1.5h"}. CCTV recording active.`,
    });

    return updatedGame;
  }

  /**
   * Complete Match (Dynamic end_time = NOW) & Enter CCTV POST_MATCH (+10 min buffer) Window
   */
  static async completeMatch(
    managerId: string,
    managerName: string,
    gameId: string,
    scoreData?: { teamAScore: number; teamBScore: number },
  ) {
    if (scoreData) {
      await updateLiveMatchScore({
        gameId,
        teamAScore: scoreData.teamAScore,
        teamBScore: scoreData.teamBScore,
        isFinal: true,
        eventText: "🏁 FINAL SCORE - MATCH COMPLETED",
        updatedByUserId: managerId,
      });
    }

    // Dynamic end_time = exact current time when manager stops match
    const completedGame = await ManagerRepository.completeMatchGame(gameId);

    // CCTV enters POST_MATCH window (+10 minutes stop deadline buffer)
    try {
      const recording = await CctvRepository.getRecordingByGame(gameId);
      if (recording) {
        await dbPool.query(
          `UPDATE public.cctv_recordings
           SET recording_status = 'POST_MATCH',
               stop_deadline = CURRENT_TIMESTAMP + INTERVAL '10 minutes',
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1;`,
          [recording.id],
        );
        await dbPool.query(
          `INSERT INTO public.cctv_recording_events (recording_id, event_type, actor_user_id, metadata)
           VALUES ($1, 'RECORDING_POST_MATCH_STARTED', $2, $3);`,
          [
            recording.id,
            managerId,
            JSON.stringify({ postMatchWindowMinutes: 10 }),
          ],
        );
      }

      // Reset camera status to ONLINE
      if (completedGame && completedGame.court_id) {
        await dbPool.query(
          `UPDATE public.cctv_cameras SET status = 'ONLINE', updated_at = CURRENT_TIMESTAMP WHERE court_id = $1;`,
          [completedGame.court_id],
        );
      }
    } catch (err) {
      logger.error(
        { err },
        `Error transitioning CCTV to POST_MATCH (+10m buffer) for Game ${gameId}`,
      );
    }

    await GamesRepository.addActivityLog({
      gameId,
      actorId: managerId,
      actorName: managerName,
      actorRoleName: "MANAGER",
      actionType: "MATCH_COMPLETED",
      details: scoreData
        ? `Match completed at ${completedGame.end_time}. Final Score: Team A ${scoreData.teamAScore} - ${scoreData.teamBScore} Team B`
        : `Match stopped at ${completedGame.end_time}. CCTV camera set to +10 min post-match recording window.`,
    });

    return completedGame;
  }

  /**
   * Cancel Match
   */
  static async cancelMatch(gameId: string) {
    return await ManagerRepository.updateGameStatus(gameId, "CANCELLED");
  }

  /**
   * Manager Player Management: List All Players (Safe fields only)
   */
  static async getAllPlayers(
    managerUserId: string,
    search?: string,
    status?: string,
    limit = 50,
    offset = 0,
  ) {
    return await ManagerRepository.getAllPlayers(search, status, limit, offset);
  }

  /**
   * Manager Player Management: Get Detailed Player Profile & Full Match/Payment History
   */
  static async getPlayerDetailHistory(managerUserId: string, playerId: string) {
    const data = await ManagerRepository.getPlayerDetailHistory(playerId);
    if (!data) {
      throw new ApiError(404, "Player not found", "PLAYER_NOT_FOUND");
    }
    return data;
  }

  /**
   * Manager Player Management: Block Player
   */
  static async blockPlayer(
    managerUserId: string,
    managerName: string,
    playerId: string,
    reason?: string,
  ) {
    const userRes = await dbPool.query(
      `SELECT id, name, email, role_id, status FROM public.users WHERE id = $1;`,
      [playerId],
    );
    if (userRes.rows.length === 0) {
      throw new ApiError(404, "Player not found", "PLAYER_NOT_FOUND");
    }
    const user = userRes.rows[0];

    if (user.role_id === 1 || user.role_id === 2) {
      throw new ApiError(
        403,
        "Forbidden: Managers and administrators cannot be suspended",
        "FORBIDDEN_USER_TYPE",
      );
    }

    if (user.status === "SUSPENDED") {
      return {
        id: user.id,
        name: user.name,
        status: "SUSPENDED",
        message: "Player is already blocked",
      };
    }

    const updated = await ManagerRepository.updatePlayerStatus(
      playerId,
      "SUSPENDED",
    );

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
       VALUES ($1, $2, 'BLOCK_PLAYER', $3, $4);`,
      [
        managerUserId,
        managerName,
        `User:${playerId}`,
        reason || "Blocked by turf club manager",
      ],
    );

    sendUserNotification(playerId, {
      title: "🚫 Account Suspended",
      message: `Your player account has been suspended by management: ${reason || "Terms of service violation"}.`,
      type: "WARNING",
    });

    return {
      id: updated.id,
      name: updated.name,
      status: updated.status,
      message: "Player blocked successfully",
    };
  }

  /**
   * Manager Player Management: Unblock Player
   */
  static async unblockPlayer(
    managerUserId: string,
    managerName: string,
    playerId: string,
  ) {
    const userRes = await dbPool.query(
      `SELECT id, name, email, role_id, status FROM public.users WHERE id = $1;`,
      [playerId],
    );
    if (userRes.rows.length === 0) {
      throw new ApiError(404, "Player not found", "PLAYER_NOT_FOUND");
    }
    const user = userRes.rows[0];

    const updated = await ManagerRepository.updatePlayerStatus(
      playerId,
      "ACTIVE",
    );

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
       VALUES ($1, $2, 'UNBLOCK_PLAYER', $3, $4);`,
      [
        managerUserId,
        managerName,
        `User:${playerId}`,
        "Unblocked by turf club manager",
      ],
    );

    sendUserNotification(playerId, {
      title: "✅ Account Restored",
      message:
        "Your player account has been unblocked. Welcome back to the arena!",
      type: "SUCCESS",
    });

    return {
      id: updated.id,
      name: updated.name,
      status: updated.status,
      message: "Player unblocked successfully",
    };
  }

  /**
   * Submit or Finalize Match Score (Server Authorized for Host, Manager, or Admin)
   */
  static async submitMatchScore(
    userId: string,
    userName: string,
    userRole: number,
    gameId: string,
    scoreData: { teamAScore: number; teamBScore: number; isFinal?: boolean },
  ) {
    const gameRes = await dbPool.query(
      "SELECT * FROM public.games WHERE id = $1;",
      [gameId],
    );
    if (gameRes.rows.length === 0)
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
    const game = gameRes.rows[0];

    if (game.status === "CANCELLED") {
      throw new ApiError(
        400,
        "Cannot submit score for a cancelled match",
        "INVALID_MATCH_STATUS",
      );
    }

    // Check if score is already submitted & locked for non-admins (Manager can enter ONCE; Admin can UPDATE anytime)
    const hasExistingScore = game.team_a_score > 0 || game.team_b_score > 0;
    if (hasExistingScore && userRole !== 1) {
      throw new ApiError(
        403,
        "Official match score is locked. Only Platform Administrators can edit or override submitted scores.",
        "SCORE_LOCKED_ADMIN_ONLY",
      );
    }

    // Role check: Only match host player (game.creator_id), club manager, or platform admin can submit scores
    if (userRole === 3) {
      if (game.creator_id !== userId) {
        throw new ApiError(
          403,
          "Forbidden: Only the match host or turf club manager can submit scores",
          "FORBIDDEN_SCORE_ENTRY",
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

    return await updateLiveMatchScore({
      gameId,
      teamAScore: scoreData.teamAScore,
      teamBScore: scoreData.teamBScore,
      isFinal: scoreData.isFinal ?? true,
      eventText: "🏁 FINAL SCORE - MATCH COMPLETED",
      updatedByUserId: userId,
    });
  }

  /**
   * Get CCTV Recording Status & Presigned Playback URL for Manager
   */
  static async getMatchRecording(managerUserId: string, gameId: string) {
    const gameRes = await dbPool.query(
      "SELECT * FROM public.games WHERE id = $1;",
      [gameId],
    );
    if (gameRes.rows.length === 0)
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
    const game = gameRes.rows[0];

    const isManager = await dbPool.query(
      `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
      [game.club_id, managerUserId],
    );
    if (isManager.rows.length === 0) {
      throw new ApiError(
        403,
        "Forbidden: You do not manage the club hosting this match",
        "FORBIDDEN_CLUB_SCOPE",
      );
    }

    const recording = await CctvRepository.getRecordingByGame(gameId);

    // Fetch all cataloged game videos (with multi-camera links)
    const videos = await GamesRepository.getGameVideos(gameId);
    const videoList: Array<any> = [];

    for (let i = 0; i < videos.length; i++) {
      const vid = videos[i];
      try {
        const url = await getSignedPlaybackUrl(vid.video_url, 3600);
        videoList.push({
          id: vid.id,
          videoId: vid.id,
          gameId: vid.game_id,
          cctvId: vid.cctv_id || null,
          cameraName: vid.camera_name || `Camera ${i + 1}`,
          cameraType: vid.camera_type || "RTSP_DOME",
          cameraStatus: vid.camera_status || "ONLINE",
          courtId: vid.court_id || game.court_id,
          courtName: vid.court_name || "Court 1",
          clubName: vid.club_name || "All Stars Turf",
          title: vid.title,
          status: vid.status,
          playbackUrl: url,
          durationSeconds: vid.duration_seconds || 5400,
          createdAt: vid.created_at,
        });
      } catch (_) {}
    }

    let singleRecordingPlaybackUrl: string | null = null;
    const objectKey = recording?.storage_object_key || recording?.s3_object_key;
    if (objectKey) {
      try {
        singleRecordingPlaybackUrl = await getSignedPlaybackUrl(
          objectKey,
          3600,
        );
      } catch (err) {
        logger.error({ err }, "Error signing playback URL for manager");
      }
    }

    const effectivePlaybackUrl =
      videoList[0]?.playbackUrl ||
      singleRecordingPlaybackUrl ||
      game.video_playback_url;

    if (!recording && videoList.length === 0 && !effectivePlaybackUrl) {
      return {
        gameId,
        status: "NOT_RECORDED",
        message: "No recording exists for this match",
        videos: [],
      };
    }

    return {
      recordingId: recording?.id || null,
      gameId: recording?.game_id || game.id,
      courtId: recording?.court_id || game.court_id,
      cameraId: recording?.camera_id || videoList[0]?.cctvId || null,
      cameraName: videoList[0]?.cameraName || "Camera 1",
      status:
        recording?.status ||
        (videoList.length > 0 ? "COMPLETED" : "NOT_RECORDED"),
      recordingStatus:
        recording?.recording_status ||
        (videoList.length > 0 ? "COMPLETED" : "NOT_RECORDED"),
      startTime:
        recording?.start_time || recording?.started_at || game.start_time,
      scheduledMatchEnd: recording?.scheduled_match_end,
      stopDeadline: recording?.stop_deadline,
      actualStopTime: recording?.actual_stop_time,
      playbackUrl: effectivePlaybackUrl,
      videos: videoList,
    };
  }

  /**
   * Manager Manual Stop CCTV Recording (Only permitted AFTER match scheduled end!)
   */
  static async stopMatchRecording(
    managerUserId: string,
    managerName: string,
    gameId: string,
  ) {
    const gameRes = await dbPool.query(
      "SELECT * FROM public.games WHERE id = $1;",
      [gameId],
    );
    if (gameRes.rows.length === 0)
      throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");
    const game = gameRes.rows[0];

    const isManager = await dbPool.query(
      `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
      [game.club_id, managerUserId],
    );
    if (isManager.rows.length === 0) {
      throw new ApiError(
        403,
        "Forbidden: You do not manage the club hosting this match",
        "FORBIDDEN_CLUB_SCOPE",
      );
    }

    // Verify scheduled end time: Manager cannot stop recording before match end! (Phase 32)
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
      String(game.end_time).length === 5
        ? `${game.end_time}:00`
        : String(game.end_time);
    const parsedEndTime = new Date(`${datePart}T${timeStr}`);
    const matchEndTime = !isNaN(parsedEndTime.getTime())
      ? parsedEndTime
      : new Date();
    const now = new Date();
    if (now < matchEndTime && game.status !== "COMPLETED") {
      throw new ApiError(
        400,
        `Cannot stop recording before scheduled match end time (${game.end_time}). Recording must continue until match completes.`,
        "RECORDING_EARLY_STOP_FORBIDDEN",
      );
    }

    const recording = await CctvRepository.getRecordingByGame(gameId);
    if (!recording) {
      throw new ApiError(
        404,
        "No active recording found for this game",
        "RECORDING_NOT_FOUND",
      );
    }

    return await CctvService.stopMatchRecording(
      managerUserId,
      managerName,
      recording.id,
    );
  }

  /**
   * Get Detailed Game info for Manager
   */
  static async getGameDetails(managerUserId: string, gameId: string) {
    const game = await ManagerRepository.getGameForManager(gameId);
    if (!game) throw new ApiError(404, "Match not found", "MATCH_NOT_FOUND");

    const isManager = await dbPool.query(
      `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
      [game.club_id, managerUserId],
    );
    if (isManager.rows.length === 0) {
      throw new ApiError(
        403,
        "Forbidden: You do not manage the club hosting this match",
        "FORBIDDEN_CLUB_SCOPE",
      );
    }

    return game;
  }
}
