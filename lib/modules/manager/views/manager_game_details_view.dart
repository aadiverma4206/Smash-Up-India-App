import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_games_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';

class ManagerGameDetailsView extends GetView<ManagerGamesController> {
  ManagerGameDetailsView({super.key});

  final TextEditingController teamAController =
      TextEditingController(text: '0');
  final TextEditingController teamBController =
      TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Match Control Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Obx(() {
        final game = controller.selectedGame.value;
        if (game == null) {
          return const AppLoader(message: 'Loading match details...');
        }

        final collectedFee = (game.currentPlayers * game.perPlayerFee);
        final statusUpper = game.status.toUpperCase();
        final isOngoing = statusUpper == 'ONGOING' || statusUpper == 'STARTED';
        final isCompleted = statusUpper == 'COMPLETED';
        final isCancelled = statusUpper == 'CANCELLED';

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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.primary,
                      width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                            color: isOngoing
                                ? Colors.orange
                                : (isCompleted
                                    ? Colors.green
                                    : (isCancelled
                                        ? Colors.redAccent
                                        : AppColors.primary)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Status: ${game.status.replaceAll("_", " ")}',
                            style: const TextStyle(
                              color: Colors.white,
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
                        color: context.textPrimary,
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
                                color: context.textSecondary,
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
                                color: context.textSecondary,
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

              // 🛡️ MANAGER CONTROLS PANEL (Active Court Match Controls)
              _buildManagerControlsPanel(context, game),
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
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: context.borderColor, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Roster Slots Filled',
                                style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '${game.currentPlayers} / ${game.maxPlayers} Players',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Per Player Fee',
                                style: TextStyle(
                                    color: context.textSecondary,
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
                              color: context.textPrimary,
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
              const SizedBox(height: 20),

              // 👥 Joined Player Roster Section
              _buildRosterPaymentSection(context, game),
              const SizedBox(height: 20),

              // 📹 CCTV RECORDING VIDEO PLAYER SECTION
              if (isCompleted || isOngoing) ...[
                _buildCctvVideoSection(context, game),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  /// 🛡️ MANAGER CONTROLS PANEL Widget (Active Court Matches)
  Widget _buildManagerControlsPanel(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusUpper = game.status.toUpperCase();
    final isCompleted = statusUpper == 'COMPLETED';
    final isCancelled = statusUpper == 'CANCELLED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182232) : const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
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
              Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.shield_outlined,
                  color: isCompleted ? Colors.green : Colors.amber,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                isCompleted
                    ? 'MATCH COMPLETED & SCORE LOCKED'
                    : 'MANAGER CONTROLS (CLUB_MANAGER)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCompleted ? Colors.green : Colors.amber.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score has been submitted and locked.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Final Score: Team A ${game.teamAScore} - ${game.teamBScore} Team B\nNote: Once added, scores can only be modified by an Administrator.',
                    style:
                        TextStyle(fontSize: 11.5, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ] else if (isCancelled) ...[
            const Text('This match has been cancelled.',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ] else ...[
            // Row 1: ▶ Start Match
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: () => controller.startGame(game.id),
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                label: Text(
                  'Start Match (${game.currentPlayers}/${game.maxPlayers} Joined)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Row 2: Finish Match & Live Score
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      onPressed: () =>
                          _showScoreDialog(context, game, isFinish: true),
                      icon: Icon(Icons.check_circle_outline_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 18),
                      label: Text(
                        'Finish Match',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 2,
                      ),
                      onPressed: () =>
                          _showScoreDialog(context, game, isFinish: false),
                      icon: const Icon(Icons.emoji_events_outlined,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Live Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Cancel Match (No Edit Match as requested)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: () => _confirmCancelMatch(context, game),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Cancel Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📹 CCTV RECORDED MATCH VIDEO SECTION Widget
  Widget _buildCctvVideoSection(BuildContext context, GameModel game) {
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
            children: [
              const Icon(Icons.videocam_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'CCTV Recorded Match Footage',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          Divider(color: context.borderColor, height: 20),
          Obx(() {
            final playbackUrl = controller.cctvPlaybackUrl.value ??
                game.videoPlaybackUrl;

            if (playbackUrl != null && playbackUrl.isNotEmpty) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded,
                            size: 56, color: AppColors.primary),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                                    '${game.courtName} • Auto-recorded via S3 CCTV',
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Get.toNamed('/videos/player', arguments: {
                          'videoUrl': playbackUrl,
                          'title': game.title,
                        });
                      },
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: AppColors.primary),
                      label: const Text('Watch Recorded Match Video',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CCTV match video is automatically recorded during the match and saved to secure storage upon completion.',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRosterPaymentSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roster = game.roster ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Joined Players & Payment Badges',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
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
          Divider(color: context.borderColor, height: 20),
          if (roster.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No players have joined this match yet.',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roster.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = roster[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInputBg
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: context.textPrimary),
                            ),
                            Text(
                              'Position: ${player.position} • OVR: ${player.ovr}',
                              style: TextStyle(
                                  fontSize: 11, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          player.team,
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showScoreDialog(BuildContext context, GameModel game,
      {required bool isFinish}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit Match Score: ${game.title}',
            style: TextStyle(color: context.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter final match score:',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: teamAController,
                    label: 'Team A Score',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: teamBController,
                    label: 'Team B Score',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () {
              final a = int.tryParse(teamAController.text.trim()) ?? 0;
              final b = int.tryParse(teamBController.text.trim()) ?? 0;
              Get.back();
              controller.submitMatchScore(game.id, a, b, isFinal: isFinish);
            },
            child: const Text('Submit Score',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelMatch(BuildContext context, GameModel game) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Match: ${game.title}',
            style: TextStyle(color: context.textPrimary)),
        content: const Text(
            'Are you sure you want to cancel this match? Full wallet refunds will be processed to joined players.',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Get.back();
              controller.cancelMatchWithRefunds(game.id, 'Cancelled by manager');
            },
            child: const Text('Confirm Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
