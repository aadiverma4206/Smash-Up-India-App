import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/match_history_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';

class PlayerHistoryDetailView extends GetView<MatchHistoryController> {
  const PlayerHistoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Match Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: Obx(() {
        final game = controller.selectedGame.value;
        if (game == null) {
          return const AppLoader(message: 'Loading match details...');
        }

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
              _buildOverviewCard(context, game),
              const SizedBox(height: 16),
              _buildScoreResultSection(
                  context, game, hasScore, isCompleted, isCancelled),
              const SizedBox(height: 20),
              if (!isCancelled) ...[
                _buildCctvSection(context, game),
                const SizedBox(height: 20),
              ],
              _buildRosterSection(context, game),
              const SizedBox(height: 20),
              _buildPlayerEntryFeeCard(context, game),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOverviewCard(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = game.status.toUpperCase() == 'COMPLETED';
    final isCancelled = game.status.toUpperCase() == 'CANCELLED';

    String startTime =
        AppDateUtils.formatTime(game.startTime, format: 'h:mm a');
    String endTime = AppDateUtils.formatTime(game.endTime, format: 'h:mm a');
    String formattedDate = 'Today';
    try {
      final parsed = DateTime.parse(game.matchDate);
      formattedDate =
          AppDateUtils.formatDate(parsed, format: 'EEE, dd MMM yyyy');
    } catch (_) {
      formattedDate = game.matchDate.split('T')[0];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : (isCancelled
                  ? Colors.red.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.format,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? Colors.green
                          : (isCancelled
                              ? Colors.redAccent
                              : Colors.amber.shade800))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isCancelled
                            ? Colors.redAccent
                            : Colors.amber.shade800),
                  ),
                ),
                child: Text(
                  'Status: ${game.status.toUpperCase()}',
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.green
                        : (isCancelled
                            ? Colors.redAccent
                            : Colors.amber.shade800),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            game.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stadium_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${game.clubName} (${game.courtName})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$formattedDate • $startTime - $endTime',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreResultSection(BuildContext context, GameModel game,
      bool hasScore, bool isCompleted, bool isCancelled) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
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
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This match was cancelled by turf management.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!hasScore) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.amber.shade700.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.amber.shade700.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.amber.shade700, shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCORE PENDING',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade800,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official score has not been submitted by Turf Manager yet.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final int scoreA = game.teamAScore;
    final int scoreB = game.teamBScore;
    final bool isTeamAWin = scoreA > scoreB;
    final bool isTeamBWin = scoreB > scoreA;
    final int goalDiff = (scoreA - scoreB).abs();
    final Color teamAColor = isTeamAWin
        ? Colors.green
        : (isTeamBWin ? Colors.redAccent : AppColors.primary);
    final Color teamBColor = isTeamBWin
        ? Colors.green
        : (isTeamAWin ? Colors.redAccent : AppColors.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.green, size: 22),
              SizedBox(width: 8),
              Text(
                'OFFICIAL MATCH RESULT',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('TEAM A',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Text('$scoreA',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: teamAColor)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Text('VS',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('TEAM B',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Text('$scoreB',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: teamBColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (isTeamAWin || isTeamBWin
                      ? Colors.green
                      : Colors.amber.shade700)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: (isTeamAWin || isTeamBWin
                          ? Colors.green
                          : Colors.amber.shade700)
                      .withValues(alpha: 0.4),
                  width: 1.2),
            ),
            child: Row(
              children: [
                Icon(
                    isTeamAWin || isTeamBWin
                        ? Icons.emoji_events_rounded
                        : Icons.handshake_rounded,
                    color: isTeamAWin || isTeamBWin
                        ? Colors.green
                        : Colors.amber.shade800,
                    size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeamAWin
                            ? 'TEAM A VICTORY (+$goalDiff ${goalDiff == 1 ? 'GOAL' : 'GOALS'})'
                            : (isTeamBWin
                                ? 'TEAM B VICTORY (+$goalDiff ${goalDiff == 1 ? 'GOAL' : 'GOALS'})'
                                : 'MATCH DRAW'),
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: isTeamAWin || isTeamBWin
                                ? Colors.green
                                : Colors.amber.shade800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTeamAWin
                            ? 'Team A Won • Team B Defeated'
                            : (isTeamBWin
                                ? 'Team B Won • Team A Defeated'
                                : 'Equal Score Shared Between Teams'),
                        style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('CCTV Recorded Match Footage',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87)),
            ],
          ),
          Divider(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              height: 20),
          Obx(() {
            final String? playbackUrl =
                controller.cctvPlaybackUrl.value ?? game.videoPlaybackUrl;
            final bool hasValidVideo = playbackUrl != null &&
                playbackUrl.isNotEmpty &&
                !playbackUrl.contains('BigBuckBunny') &&
                !playbackUrl.contains('sample/');

            if (hasValidVideo) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/videos/player', arguments: {
                        'videoUrl': playbackUrl,
                        'playbackUrl': playbackUrl,
                        'title': '${game.title} - CCTV Footage',
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded,
                              size: 56, color: AppColors.primary),
                        ],
                      ),
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
                          'playbackUrl': playbackUrl,
                          'title': '${game.title} - CCTV Footage',
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF182232) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_off_rounded,
                        size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No CCTV Video Recording Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No camera recording was saved for this match.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Joined Players & Roster',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${roster.length} Players',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              height: 20),
          Obx(() {
            final activeTab =
                controller.selectedRosterTeamFilter.value == 'TEAM_B'
                    ? 'TEAM_B'
                    : 'TEAM_A';
            final teamACount = roster.where((p) => p.isTeamA).length;
            final teamBCount = roster.where((p) => p.isTeamB).length;

            return Row(
              children: [
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
                                : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 15,
                              color: activeTab == 'TEAM_A'
                                  ? Colors.white
                                  : Colors.green),
                          const SizedBox(width: 6),
                          Text('Team A ($teamACount)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 'TEAM_A'
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                                : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 15,
                              color: activeTab == 'TEAM_B'
                                  ? Colors.white
                                  : Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text('Team B ($teamBCount)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 'TEAM_B'
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87))),
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
                ? roster.where((p) => p.isTeamB).toList()
                : roster.where((p) => p.isTeamA).toList();

            if (filteredRoster.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    filterTab == 'TEAM_A'
                        ? 'No players assigned to Team A in this match.'
                        : 'No players assigned to Team B in this match.',
                    style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                        fontSize: 13),
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
                final isTeamA = player.isTeamA;
                final hasImage = player.profileImageUrl.isValidNetworkUrl;

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
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (isTeamA ? Colors.green : Colors.blue)
                            .withValues(alpha: 0.18),
                        backgroundImage: hasImage
                            ? NetworkImage(player.profileImageUrl!)
                            : null,
                        child: !hasImage
                            ? Text(
                                player.name.isNotEmpty
                                    ? player.name[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                    color: isTeamA
                                        ? Colors.green
                                        : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : Colors.black87)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                      color: (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(player.position,
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87)),
                                ),
                              ],
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
                              width: 1),
                        ),
                        child: Text(isTeamA ? 'TEAM A' : 'TEAM B',
                            style: TextStyle(
                                color: isTeamA
                                    ? Colors.green
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5)),
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

  Widget _buildPlayerEntryFeeCard(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double myFee = game.perPlayerFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Player Match Fee Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Paid Entry Fee:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
              Text(
                '₹${myFee.toStringAsFixed(0)}',
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
    );
  }
}
