import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_games_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
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

        if (controller.teamAPlayers.isEmpty &&
            controller.teamBPlayers.isEmpty &&
            (game.roster == null || game.roster!.isEmpty) &&
            !controller.isLoadingRoster.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.fetchGamePlayers(game.id);
          });
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
              _buildManagerControlsPanel(context, game),
              const SizedBox(height: 20),
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
              _buildRosterPaymentSection(context, game),
              const SizedBox(height: 20),
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

  Widget _buildManagerControlsPanel(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusUpper = game.status.toUpperCase();
    final isOngoing = statusUpper == 'ONGOING' ||
        statusUpper == 'STARTED' ||
        statusUpper == 'PAUSED';
    final isPaused = statusUpper == 'PAUSED';
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
                      : (isOngoing
                          ? Icons.sensors_rounded
                          : Icons.shield_outlined),
                  color: isCompleted
                      ? Colors.green
                      : (isOngoing ? Colors.green : Colors.amber),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                isCompleted
                    ? 'MATCH COMPLETED & SCORE LOCKED'
                    : (isOngoing
                        ? 'ACTIVE MATCH CONTROLS'
                        : 'MANAGER CONTROLS (CLUB_MANAGER)'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCompleted
                      ? Colors.green
                      : (isOngoing ? Colors.green : Colors.amber.shade800),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Match Completed',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Final Score: Team A ${game.teamAScore} - ${game.teamBScore} Team B',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _showScoreEntryDialog(context, game),
                    icon: const Icon(Icons.edit_note_rounded,
                        color: Colors.green, size: 16),
                    label: const Text('Edit Score',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else if (isCancelled) ...[
            const Text('This match has been cancelled.',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ] else if (isOngoing) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isPaused ? Colors.amber : Colors.green)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPaused ? Colors.amber : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPaused
                        ? Icons.pause_circle_filled_rounded
                        : Icons.sensors_rounded,
                    color: isPaused ? Colors.amber.shade800 : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPaused
                          ? 'Match is currently PAUSED'
                          : 'Match is ONGOING & LIVE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPaused ? Colors.amber.shade800 : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isPaused
                              ? AppColors.primary
                              : Colors.amber.shade700,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      onPressed: () => controller.togglePauseGame(game.id),
                      icon: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: isPaused
                            ? AppColors.primary
                            : Colors.amber.shade700,
                        size: 20,
                      ),
                      label: Text(
                        isPaused ? 'Resume' : 'Pause',
                        style: TextStyle(
                          color: isPaused
                              ? AppColors.primary
                              : Colors.amber.shade700,
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
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 2,
                      ),
                      onPressed: () => _confirmStopMatch(context, game),
                      icon: const Icon(Icons.stop_rounded,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Stop Match',
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: () => _showScoreEntryDialog(context, game),
                icon: const Icon(Icons.sports_score_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  'Update Live Match Score (${game.teamAScore} - ${game.teamBScore})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: () => _showExtendTimeDialog(context, game),
                icon: const Icon(Icons.more_time_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Extend Match Time (+ Extra Mins)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => _confirmCancelMatch(context, game),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 18),
                label: const Text(
                  'Cancel Match',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ] else ...[
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => _showRescheduleDialog(context, game),
                icon: const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.primary, size: 20),
                label: const Text(
                  'Reschedule Match',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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

  Widget _buildCctvVideoSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = game.status.toUpperCase() == 'COMPLETED';

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
                      color: context.textPrimary,
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
                  child: Text(
                    count > 1 ? '$count CAMERAS' : '1 CAMERA',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ),
          Divider(color: context.borderColor, height: 20),
          Obx(() {
            if (controller.isLoadingVideos.value) {
              return Container(
                height: 160,
                width: double.infinity,
                alignment: Alignment.center,
                child:
                    const CircularProgressIndicator(color: AppColors.primary),
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
                    : game.videoPlaybackUrl);

            final bool hasValidVideo = playbackUrl != null &&
                playbackUrl.trim().isNotEmpty &&
                !playbackUrl.contains('BigBuckBunny') &&
                !playbackUrl.contains('commondatastorage.googleapis.com') &&
                !playbackUrl.contains('sample/');

            if (hasValidVideo) {
              final cameraDisplayName = selectedVid?.cameraName ?? 'Camera 1';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (videos.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(videos.length, (index) {
                          final vid = videos[index];
                          final isSelected = selectedVid?.id == vid.id ||
                              (selectedVid == null && index == 0);
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: 8, bottom: 10),
                            child: InkWell(
                              onTap: () => controller.selectCamera(vid),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? const Color(0xFF1E2822)
                                          : const Color(0xFFF1F5F2)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      vid.cameraName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : context.textPrimary,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/videos/player', arguments: {
                        'videoUrl': playbackUrl,
                        'title': '${game.title} - $cameraDisplayName',
                        'cameras': videos.map((v) => v.toJson()).toList(),
                        'initialIndex':
                            videos.indexWhere((v) => v.id == selectedVid?.id),
                      });
                    },
                    child: Container(
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
                                      '${game.courtName} • $cameraDisplayName • Auto-recorded via S3 CCTV',
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
                          'title': '${game.title} - $cameraDisplayName',
                          'cameras': videos.map((v) => v.toJson()).toList(),
                          'initialIndex':
                              videos.indexWhere((v) => v.id == selectedVid?.id),
                        });
                      },
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: AppColors.primary),
                      label: Text(
                          'Watch Recorded Match Video ($cameraDisplayName)',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            if (isCompleted) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Match Video Processing',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Final footage will be released & visible in the UI 10 minutes after match completion.',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: EmptyStateWidget(
                title: 'No CCTV Footage Available',
                subtitle:
                    'Footage will be automatically recorded and displayed here once the match starts.',
                imageSize: 130,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRosterPaymentSection(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final roster = (controller.selectedGame.value?.roster != null &&
              controller.selectedGame.value!.roster!.isNotEmpty)
          ? controller.selectedGame.value!.roster!
          : (controller.teamAPlayers.isNotEmpty ||
                  controller.teamBPlayers.isNotEmpty)
              ? [...controller.teamAPlayers, ...controller.teamBPlayers]
              : (game.roster ?? []);

      final activeTab = controller.selectedRosterTeamFilter.value == 'ALL'
          ? 'TEAM_A'
          : controller.selectedRosterTeamFilter.value;

      final teamAPlayers = roster.where((p) => p.isTeamA).toList();
      final teamBPlayers = roster.where((p) => p.isTeamB).toList();

      final teamACount = teamAPlayers.length;
      final teamBCount = teamBPlayers.length;
      final totalPlayers = roster.length;

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
              children: [
                Expanded(
                  child: Text(
                    'Joined Players & Payment Badges',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalPlayers Players',
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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_A',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: activeTab == 'TEAM_A'
                            ? Colors.green
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
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
                            Icons.shield_rounded,
                            size: 16,
                            color: activeTab == 'TEAM_A'
                                ? Colors.white
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Team A ($teamACount)',
                            style: TextStyle(
                              fontSize: 12.5,
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
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_B',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: activeTab == 'TEAM_B'
                            ? Colors.blue.shade700
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
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
                            Icons.shield_rounded,
                            size: 16,
                            color: activeTab == 'TEAM_B'
                                ? Colors.white
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Team B ($teamBCount)',
                            style: TextStyle(
                              fontSize: 12.5,
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
            ),
            const SizedBox(height: 14),
            Builder(builder: (context) {
              final displayedPlayers =
                  activeTab == 'TEAM_B' ? teamBPlayers : teamAPlayers;
              final isTeamA = activeTab == 'TEAM_A';

              if (displayedPlayers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isTeamA
                          ? 'No players assigned to Team A in this match.'
                          : 'No players assigned to Team B in this match.',
                      style:
                          TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedPlayers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final player = displayedPlayers[index];
                  final paymentStatus = player.paymentStatus.toUpperCase();
                  final isPaid = paymentStatus == 'PAID' ||
                      paymentStatus == 'COMPLETED' ||
                      paymentStatus == 'SUCCESS';
                  final isPending = paymentStatus == 'PENDING';
                  final isRefunded = paymentStatus == 'REFUNDED';

                  final badgeColor = isPaid
                      ? Colors.green
                      : (isPending
                          ? Colors.orange
                          : (isRefunded
                              ? Colors.deepOrange
                              : Colors.redAccent));

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInputBg
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTeamA
                            ? Colors.green.withValues(alpha: 0.25)
                            : Colors.blue.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor:
                              (isTeamA ? Colors.green : Colors.blue)
                                  .withValues(alpha: 0.18),
                          backgroundImage: (player.profileImageUrl != null &&
                                  player.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(player.profileImageUrl!)
                              : null,
                          child: (player.profileImageUrl == null ||
                                  player.profileImageUrl!.isEmpty)
                              ? Text(
                                  player.name.isNotEmpty
                                      ? player.name[0].toUpperCase()
                                      : 'P',
                                  style: TextStyle(
                                    color: isTeamA
                                        ? Colors.green
                                        : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
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
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    'Pos: ${player.position}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  if (player.phone != null &&
                                      player.phone!.isNotEmpty) ...[
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        player.phone!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Payment Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaid
                                    ? Icons.check_circle_rounded
                                    : (isPending
                                        ? Icons.hourglass_top_rounded
                                        : (isRefunded
                                            ? Icons.replay_rounded
                                            : Icons.cancel_rounded)),
                                size: 12,
                                color: badgeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPaid
                                    ? 'PAID'
                                    : (isPending
                                        ? 'PENDING'
                                        : (isRefunded ? 'REFUND' : 'UNPAID')),
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
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
    });
  }

  void _showExtendTimeDialog(BuildContext context, GameModel game) {
    int selectedMinutes = 15;
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.more_time_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extend Match Time',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select extra minutes to extend for match "${game.title}" and its live CCTV recording:',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [10, 15, 30].map((mins) {
                    final isSel = selectedMinutes == mins;
                    return ChoiceChip(
                      label: Text('+$mins Mins'),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => selectedMinutes = mins);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: controller.isExtendingTime.value
                        ? null
                        : () {
                            Get.back();
                            controller.extendMatchTime(game.id,
                                additionalMinutes: selectedMinutes);
                          },
                    child: controller.isExtendingTime.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Extend +$selectedMinutes Min',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showScoreEntryDialog(BuildContext context, GameModel game) {
    final scoreAController =
        TextEditingController(text: game.teamAScore.toString());
    final scoreBController =
        TextEditingController(text: game.teamBScore.toString());
    final isFinalRx = (game.status == 'COMPLETED').obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          game.status == 'COMPLETED' ? 'Edit Match Score' : 'Update Live Score',
          style: TextStyle(color: context.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter scores for "${game.title}". Players will immediately see this updated on their match scoreboard.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team A',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: scoreAController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VS',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team B',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: scoreBController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => Row(
                  children: [
                    Checkbox(
                      value: isFinalRx.value,
                      activeColor: AppColors.primary,
                      onChanged: (val) => isFinalRx.value = val ?? false,
                    ),
                    const Text('Mark as Final Score',
                        style: TextStyle(fontSize: 12)),
                  ],
                )),
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
              final a = int.tryParse(scoreAController.text.trim()) ?? 0;
              final b = int.tryParse(scoreBController.text.trim()) ?? 0;
              Get.back();
              controller.submitMatchScore(game.id, a, b,
                  isFinal: isFinalRx.value);
            },
            child: const Text('Save Score',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmStopMatch(BuildContext context, GameModel game) {
    final scoreAController =
        TextEditingController(text: game.teamAScore.toString());
    final scoreBController =
        TextEditingController(text: game.teamBScore.toString());

    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Stop & Complete Match: ${game.title}',
            style: TextStyle(color: context.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the final score before completing this match:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team A',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: scoreAController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('-',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team B',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: scoreBController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final a = int.tryParse(scoreAController.text.trim()) ?? 0;
              final b = int.tryParse(scoreBController.text.trim()) ?? 0;
              Get.back();
              controller.completeGame(game.id, a, b);
            },
            child: const Text('Stop & Complete',
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
              controller.cancelMatchWithRefunds(
                  game.id, 'Cancelled by manager');
            },
            child: const Text('Confirm Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, GameModel game) {
    DateTime selectedDate = DateTime.tryParse(game.matchDate) ?? DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = TimeOfDay.now();

    try {
      if (game.startTime.contains(':')) {
        final parts = game.startTime.split(':');
        selectedStartTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 18,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    } catch (_) {}

    try {
      if (game.endTime.contains(':')) {
        final parts = game.endTime.split(':');
        selectedEndTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 19,
          minute: int.tryParse(parts[1]) ?? 30,
        );
      }
    } catch (_) {}

    final reasonController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) {
          String formatTime(TimeOfDay tod) {
            final h = tod.hour.toString().padLeft(2, '0');
            final m = tod.minute.toString().padLeft(2, '0');
            return '$h:$m:00';
          }

          String formatDate(DateTime dt) {
            final y = dt.year.toString();
            final m = dt.month.toString().padLeft(2, '0');
            final d = dt.day.toString().padLeft(2, '0');
            return '$y-$m-$d';
          }

          return AlertDialog(
            backgroundColor: context.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reschedule Match',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update the scheduled date & time for "${game.title}". All joined players will receive an instant notification.',
                    style:
                        TextStyle(fontSize: 12.5, color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('New Match Date',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.isBefore(DateTime.now())
                            ? DateTime.now()
                            : selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDate(selectedDate),
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Time',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedStartTime,
                                );
                                if (picked != null) {
                                  setState(() => selectedStartTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: context.borderColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedStartTime.format(context),
                                      style: TextStyle(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    const Icon(Icons.access_time_rounded,
                                        size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End Time',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedEndTime,
                                );
                                if (picked != null) {
                                  setState(() => selectedEndTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: context.borderColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedEndTime.format(context),
                                      style: TextStyle(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    const Icon(Icons.access_time_filled_rounded,
                                        size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Reason for Rescheduling (Optional)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Ground maintenance, weather delay, requested by players',
                      hintStyle:
                          TextStyle(color: context.textSecondary, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel',
                    style: TextStyle(color: context.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  final formattedDate = formatDate(selectedDate);
                  final formattedStart = formatTime(selectedStartTime);
                  final formattedEnd = formatTime(selectedEndTime);

                  Get.back();
                  await controller.rescheduleMatch(
                    gameId: game.id,
                    matchDate: formattedDate,
                    startTime: formattedStart,
                    endTime: formattedEnd,
                    courtId: game.courtId,
                    reason: reasonController.text.trim(),
                  );
                },
                child: const Text('Confirm Reschedule',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
