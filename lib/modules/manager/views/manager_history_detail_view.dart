import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_games_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';

class ManagerHistoryDetailView extends GetView<ManagerGamesController> {
  ManagerHistoryDetailView({super.key});

  final TextEditingController teamAController = TextEditingController(text: '0');
  final TextEditingController teamBController = TextEditingController(text: '0');

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
                            color: (isCompleted ? Colors.green : Colors.redAccent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isCompleted ? Colors.green : Colors.redAccent),
                          ),
                          child: Text(
                            'Status: ${game.status.replaceAll("_", " ")}',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.redAccent,
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
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
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
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
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
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
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
                            color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Roster Slots Filled',
                                style: TextStyle(
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '${game.currentPlayers} / ${game.maxPlayers} Players',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Per Player Fee',
                                style: TextStyle(
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
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
                              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
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
              _buildRosterSection(context, game),
              const SizedBox(height: 20),

              // 📹 CCTV RECORDED MATCH VIDEO SECTION
              _buildCctvSection(context, game),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  /// 🏆 SCORE ENTRY OR LOCKED SCORE Widget
  Widget _buildHistoryScoreSection(BuildContext context, GameModel game, bool hasScore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Icon(hasScore ? Icons.check_circle_rounded : Icons.sports_score_rounded,
                  color: hasScore ? Colors.green : AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                hasScore ? 'FINAL MATCH SCORE (LOCKED)' : 'ENTER MATCH SCORE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: hasScore ? Colors.green : AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasScore) ...[
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
                  Text(
                    'Final Score: Team A ${game.teamAScore} - ${game.teamBScore} Team B',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Score has been submitted and locked. Once entered, scores can only be modified by an Administrator.',
                    style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Option to enter score if not yet submitted
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: () => _showScoreDialog(context, game),
                icon: const Icon(Icons.sports_score_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Submit Match Score',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 👥 Roster Player List
  Widget _buildRosterSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roster = game.roster ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
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
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, height: 20),
          if (roster.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No player details recorded for this match.',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, fontSize: 13),
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
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                            ),
                            Text(
                              'Position: ${player.position} • OVR: ${player.ovr}',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          player.team,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
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

  /// 📹 CCTV Recorded Video Section
  Widget _buildCctvSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'CCTV Recorded Match Footage',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ],
          ),
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, height: 20),
          Obx(() {
            final playbackUrl = controller.cctvPlaybackUrl.value ?? game.videoPlaybackUrl;

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
                        const Icon(Icons.play_circle_fill_rounded, size: 56, color: AppColors.primary),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_outlined, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${game.courtName} • Auto-recorded via S3 CCTV',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Get.toNamed('/videos/player', arguments: {
                          'videoUrl': playbackUrl,
                          'title': game.title,
                        });
                      },
                      icon: const Icon(Icons.fullscreen_rounded, color: AppColors.primary),
                      label: const Text('Watch Recorded Match Video', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CCTV match video is automatically recorded during the match and saved to secure storage upon completion.',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700, fontSize: 12),
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

  void _showScoreDialog(BuildContext context, GameModel game) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit Match Score: ${game.title}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter final match score:', style: TextStyle(fontSize: 12)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final a = int.tryParse(teamAController.text.trim()) ?? 0;
              final b = int.tryParse(teamBController.text.trim()) ?? 0;
              Get.back();
              controller.submitMatchScore(game.id, a, b, isFinal: true);
            },
            child: const Text('Submit Score', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
