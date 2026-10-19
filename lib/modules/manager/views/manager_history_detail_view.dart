import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_games_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/services/auth_service.dart';

class ManagerHistoryDetailView extends GetView<ManagerGamesController> {
  ManagerHistoryDetailView({super.key});

  final TextEditingController teamAController =
      TextEditingController(text: '0');
  final TextEditingController teamBController =
      TextEditingController(text: '0');
  final RxBool isEditingScore = false.obs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Match History Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: Obx(() {
        final game = controller.selectedGame.value;
        if (game == null) {
          return const AppLoader(message: 'Loading match history details...');
        }

        final collectedFee = (game.currentPlayers * game.perPlayerFee);
        final statusUpper = game.status.toUpperCase();
        final isCompleted = statusUpper == 'COMPLETED';
        final isCancelled = statusUpper == 'CANCELLED';
        final bool hasScore = (game.teamAScore > 0 || game.teamBScore > 0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⚽ Match Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.redAccent.withValues(alpha: 0.4),
                      width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            game.format,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                (isCompleted ? Colors.green : Colors.redAccent)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.redAccent),
                          ),
                          child: Text(
                            'Status: ${game.status.replaceAll("_", " ")}',
                            style: TextStyle(
                              color:
                                  isCompleted ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.stadium_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${game.clubName} (${game.courtName})',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppDateUtils.formatDate(game.matchDate, format: "EEE, dd MMM yyyy")} • ${AppDateUtils.formatTimeRange(game.startTime, game.endTime)}',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🏆 SCORE ENTRY & RESULT SECTION
              _buildHistoryScoreSection(context, game, hasScore),
              const SizedBox(height: 20),

              // 📹 CCTV RECORDED MATCH VIDEO SECTION (Hidden if Cancelled)
              if (!isCancelled) ...[
                _buildCctvSection(context, game),
                const SizedBox(height: 20),
              ],

              // 👥 Joined Player Roster Section (BELOW VIDEO as requested!)
              _buildRosterSection(context, game),
              const SizedBox(height: 20),

              // 💰 Revenue & Roster Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Entry Fee & Revenue Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.grey.shade300,
                        height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Roster Slots Filled',
                                style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey.shade600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '${game.currentPlayers} / ${game.maxPlayers} Players',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Per Player Fee',
                                style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey.shade600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${game.perPlayerFee.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Collected Entry Fees:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            )),
                        Text(
                          '₹${collectedFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  /// 🏆 DIRECT INLINE SCORE ENTRY CARD & LOCKED SCOREBOARD SYSTEM
  Widget _buildHistoryScoreSection(
      BuildContext context, GameModel game, bool hasScore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCancelled = game.status.toUpperCase() == 'CANCELLED';

    // 🚫 CANCELLED MATCH NOTICE (No scores or changes allowed for cancelled matches)
    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MATCH CANCELLED',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This match was cancelled. Scores, player stats, and CCTV video recordings are disabled for cancelled matches.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (hasScore) {
      // 🔒 LOCKED OFFICIAL SCOREBOARD CARD (Once entered, manager cannot edit - Admin only)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.green, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'OFFICIAL MATCH RESULT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'SCORE LOCKED',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 🏆 Modern Scoreboard Display Box (Win = Green, Lose = Red)
            Builder(
              builder: (context) {
                final int scoreA = game.teamAScore;
                final int scoreB = game.teamBScore;
                final Color teamAColor = scoreA > scoreB
                    ? Colors.green
                    : (scoreA < scoreB ? Colors.redAccent : AppColors.primary);
                final Color teamBColor = scoreB > scoreA
                    ? Colors.green
                    : (scoreB < scoreA ? Colors.redAccent : AppColors.primary);

                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFDCFCE7),
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Team A Column
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TEAM A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${game.teamAScore}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: teamAColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VS Divider Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      // Team B Column
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TEAM B',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${game.teamBScore}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: teamBColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 🏆 WIN / LOSE / DRAW Match Result Badge UI/UX
            Builder(
              builder: (context) {
                final int scoreA = game.teamAScore;
                final int scoreB = game.teamBScore;
                final bool isTeamAWin = scoreA > scoreB;
                final bool isTeamBWin = scoreB > scoreA;
                final int goalDiff = (scoreA - scoreB).abs();

                if (isTeamAWin) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEAM A VICTORY (+$goalDiff ${goalDiff == 1 ? 'GOAL' : 'GOALS'})',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Team A Won • Team B Defeated',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'WINNER: TEAM A',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (isTeamBWin) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEAM B VICTORY (+$goalDiff ${goalDiff == 1 ? 'GOAL' : 'GOALS'})',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Team B Won • Team A Defeated',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'WINNER: TEAM B',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.amber.shade700.withValues(alpha: 0.4),
                          width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MATCH DRAW ($scoreA - $scoreB)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Equal Score Shared Between Teams',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MATCH DRAW',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            // 🔐 ADMIN ONLY OVERRIDE SCORE OPTION
            if (AuthService.to.currentUser.value?.roleId == 1) ...[
              const SizedBox(height: 12),
              Obx(() {
                if (isEditingScore.value) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'ADMIN OVERRIDE SCORE INPUTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Team A Score Stepper
                            Column(
                              children: [
                                const Text('TEAM A',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        int val = int.tryParse(
                                                teamAController.text) ??
                                            0;
                                        if (val > 0) {
                                          teamAController.text =
                                              (val - 1).toString();
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 42,
                                      child: TextField(
                                        controller: teamAController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        int val = int.tryParse(
                                                teamAController.text) ??
                                            0;
                                        teamAController.text =
                                            (val + 1).toString();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Team B Score Stepper
                            Column(
                              children: [
                                const Text('TEAM B',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        int val = int.tryParse(
                                                teamBController.text) ??
                                            0;
                                        if (val > 0) {
                                          teamBController.text =
                                              (val - 1).toString();
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 42,
                                      child: TextField(
                                        controller: teamBController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        int val = int.tryParse(
                                                teamBController.text) ??
                                            0;
                                        teamBController.text =
                                            (val + 1).toString();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => isEditingScore.value = false,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  final valA =
                                      int.tryParse(teamAController.text) ?? 0;
                                  final valB =
                                      int.tryParse(teamBController.text) ?? 0;
                                  await controller.submitMatchScore(
                                      game.id, valA, valB);
                                  isEditingScore.value = false;
                                },
                                icon: const Icon(Icons.save_rounded,
                                    size: 18, color: Colors.white),
                                label: const Text('Save Override',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: Colors.green.shade700, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      teamAController.text = game.teamAScore.toString();
                      teamBController.text = game.teamBScore.toString();
                      isEditingScore.value = true;
                    },
                    icon: Icon(Icons.edit_note_rounded,
                        color: Colors.green.shade700, size: 18),
                    label: Text(
                      'Edit & Override Official Score (Admin Only)',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    // ⚽ PENDING SCORE ENTRY CARD (Shown when score has NOT been entered yet)
    teamAController.text = '0';
    teamBController.text = '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182232) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_score_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'ENTER FINAL MATCH SCORE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Text(
                  'PENDING SCORE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score Inputs Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A Card Input
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'TEAM A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              int val =
                                  int.tryParse(teamAController.text.trim()) ??
                                      0;
                              if (val > 0) {
                                teamAController.text = (val - 1).toString();
                              }
                            },
                            icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Colors.grey,
                                size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                          Expanded(
                            child: TextField(
                              controller: teamAController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 6),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              int val =
                                  int.tryParse(teamAController.text.trim()) ??
                                      0;
                              teamAController.text = (val + 1).toString();
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                color: AppColors.primary, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // VS Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ),

              // Team B Card Input
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'TEAM B',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              int val =
                                  int.tryParse(teamBController.text.trim()) ??
                                      0;
                              if (val > 0) {
                                teamBController.text = (val - 1).toString();
                              }
                            },
                            icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Colors.grey,
                                size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                          Expanded(
                            child: TextField(
                              controller: teamBController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 6),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              int val =
                                  int.tryParse(teamBController.text.trim()) ??
                                      0;
                              teamBController.text = (val + 1).toString();
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                color: AppColors.primary, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 💾 One-Time Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 2,
              ),
              onPressed: () {
                final a = int.tryParse(teamAController.text.trim()) ?? 0;
                final b = int.tryParse(teamBController.text.trim()) ?? 0;
                FocusScope.of(context).unfocus();
                controller.submitMatchScore(game.id, a, b, isFinal: true);
              },
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              label: const Text(
                'Submit Final Match Score',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Roster Player List (With Team A & Team B Filter Tabs)
  Widget _buildRosterSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roster = game.roster ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Joined Players & Roster',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${roster.length} Players',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              height: 20),

          // 🏆 Team A & Team B Filter Tabs (Only Team A & Team B)
          Obx(() {
            final activeTab =
                controller.selectedRosterTeamFilter.value == 'TEAM_B'
                    ? 'TEAM_B'
                    : 'TEAM_A';
            final teamACount =
                roster.where((p) => p.team.toUpperCase().contains('A')).length;
            final teamBCount =
                roster.where((p) => p.team.toUpperCase().contains('B')).length;

            return Row(
              children: [
                // TEAM A Filter Pill
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_A',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 'TEAM_A'
                            ? Colors.green
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activeTab == 'TEAM_A'
                              ? Colors.green
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: activeTab == 'TEAM_A'
                                ? Colors.white
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Team A ($teamACount)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 'TEAM_A'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // TEAM B Filter Pill
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_B',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 'TEAM_B'
                            ? Colors.blue.shade700
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activeTab == 'TEAM_B'
                              ? Colors.blue.shade700
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: activeTab == 'TEAM_B'
                                ? Colors.white
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Team B ($teamBCount)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 'TEAM_B'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 14),

          Obx(() {
            final filterTab =
                controller.selectedRosterTeamFilter.value == 'TEAM_B'
                    ? 'TEAM_B'
                    : 'TEAM_A';
            final filteredRoster = filterTab == 'TEAM_B'
                ? roster
                    .where((p) => p.team.toUpperCase().contains('B'))
                    .toList()
                : roster
                    .where((p) => p.team.toUpperCase().contains('A'))
                    .toList();

            if (filteredRoster.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  filterTab == 'TEAM_A'
                      ? 'No players assigned to Team A in this match.'
                      : (filterTab == 'TEAM_B'
                          ? 'No players assigned to Team B in this match.'
                          : 'No player details recorded for this match.'),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRoster.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = filteredRoster[index];
                final isTeamA = player.team.toUpperCase().contains('A');

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTeamA
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: (isTeamA ? Colors.green : Colors.blue)
                            .withValues(alpha: 0.18),
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            color:
                                isTeamA ? Colors.green : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Position: ${player.position} • OVR: ${player.ovr}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isTeamA ? Colors.green : Colors.blue.shade700)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isTeamA ? Colors.green : Colors.blue.shade700,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isTeamA ? 'TEAM A' : 'TEAM B',
                          style: TextStyle(
                            color:
                                isTeamA ? Colors.green : Colors.blue.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  /// 🎥 CCTV Recorded Video Section (With Dynamic Multi-Camera Switcher)
  Widget _buildCctvSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'CCTV Recorded Match Footage',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                ],
              ),
              Obx(() {
                final count = controller.matchVideos.length;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        count > 1 ? '$count CAMERAS' : '1 CAMERA',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          Divider(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              height: 20),
          Obx(() {
            if (controller.isLoadingVideos.value) {
              return Container(
                height: 180,
                width: double.infinity,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Loading Court CCTV Cameras...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final videos = controller.matchVideos;
            final selectedVid = controller.selectedVideo.value ??
                (videos.isNotEmpty ? videos.first : null);
            final playbackUrl = (controller.cctvPlaybackUrl.value != null &&
                    controller.cctvPlaybackUrl.value!.isNotEmpty)
                ? controller.cctvPlaybackUrl.value!
                : ((selectedVid != null && selectedVid.playbackUrl.isNotEmpty)
                    ? selectedVid.playbackUrl
                    : (game.videoPlaybackUrl ?? ''));

            if (playbackUrl.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.video_camera_back_outlined,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No CCTV footage recorded for this match.',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            final cameraDisplayName = selectedVid?.cameraName ?? 'Camera 1';
            final courtDisplayName = selectedVid?.courtName ?? game.courtName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎥 Dynamic Camera Selector (Admin & Manager multi-camera switcher)
                if (videos.length > 1) ...[
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'SELECT COURT CAMERA VIEW (${videos.length} AVAILABLE)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(videos.length, (index) {
                        final vid = videos[index];
                        final isSelected = selectedVid?.id == vid.id ||
                            (selectedVid == null && index == 0);
                        final label = vid.cameraName.isNotEmpty
                            ? (vid.cameraName.contains('Camera')
                                ? vid.cameraName
                                : 'Camera ${index + 1}: ${vid.cameraName}')
                            : (index == 0
                                ? 'Live Camera 1'
                                : 'Camera ${index + 1}');

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => controller.selectCamera(vid),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? const Color(0xFF1E2822)
                                        : const Color(0xFFF1F5F2)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : Colors.grey.shade300),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.videocam_rounded
                                        : Icons.videocam_outlined,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 🎬 Video Thumbnail Preview Screen
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/videos/player', arguments: {
                      'videoUrl': playbackUrl,
                      'playbackUrl': playbackUrl,
                      'title': '${game.title} - $cameraDisplayName',
                      'cameras': videos.map((v) => v.toJson()).toList(),
                      'initialIndex':
                          videos.indexWhere((v) => v.id == selectedVid?.id),
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 195,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded,
                            size: 62, color: AppColors.primary),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.live_tv_rounded,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'CCTV HD STREAM ${videos.isNotEmpty ? "• ${cameraDisplayName.toUpperCase()}" : ""}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (videos.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${videos.indexOf(selectedVid ?? videos.first) + 1} of ${videos.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_outlined,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$courtDisplayName • $cameraDisplayName • Auto-recorded S3 CCTV Footage',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Get.toNamed('/videos/player', arguments: {
                        'videoUrl': playbackUrl,
                        'playbackUrl': playbackUrl,
                        'title': '${game.title} - $cameraDisplayName',
                        'cameras': videos.map((v) => v.toJson()).toList(),
                        'initialIndex':
                            videos.indexWhere((v) => v.id == selectedVid?.id),
                      });
                    },
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                    label: Text(
                      'Watch Recorded Match Video ($cameraDisplayName)',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
