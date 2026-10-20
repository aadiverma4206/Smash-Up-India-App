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
                    'Final Score: Team A ${game.teamAScore} - ${game.teamBScore} Team B\nNote: To add or edit final scores, please go to Match History.',
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
            const SizedBox(height: 12),
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

            final cameraDisplayName = selectedVid?.cameraName ?? 'Camera 1';

            if (playbackUrl != null && playbackUrl.isNotEmpty) {
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
          Obx(() {
            final activeTab = controller.selectedRosterTeamFilter.value;
            final teamACount =
                roster.where((p) => p.team.toUpperCase().contains('A')).length;
            final teamBCount =
                roster.where((p) => p.team.toUpperCase().contains('B')).length;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'ALL',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: activeTab == 'ALL'
                            ? AppColors.primary
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeTab == 'ALL'
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 14,
                            color: activeTab == 'ALL'
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'All Players (${roster.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 'ALL'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_A',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: activeTab == 'TEAM_A'
                                ? Colors.white
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Team A ($teamACount)',
                            style: TextStyle(
                              fontSize: 11.5,
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        controller.selectedRosterTeamFilter.value = 'TEAM_B',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: activeTab == 'TEAM_B'
                                ? Colors.white
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Team B ($teamBCount)',
                            style: TextStyle(
                              fontSize: 11.5,
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
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          Obx(() {
            final filterTab = controller.selectedRosterTeamFilter.value;
            List<GameRosterPlayerModel> filteredRoster;
            if (filterTab == 'TEAM_A') {
              filteredRoster = roster
                  .where((p) => p.team.toUpperCase().contains('A'))
                  .toList();
            } else if (filterTab == 'TEAM_B') {
              filteredRoster = roster
                  .where((p) => p.team.toUpperCase().contains('B'))
                  .toList();
            } else {
              filteredRoster = roster;
            }

            if (filteredRoster.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  filterTab == 'TEAM_A'
                      ? 'No players assigned to Team A in this match.'
                      : (filterTab == 'TEAM_B'
                          ? 'No players assigned to Team B in this match.'
                          : 'No players have joined this match yet.'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
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
                        ? AppColors.darkInputBg
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
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Position: ${player.position} • OVR: ${player.ovr}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.textSecondary,
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

  void _confirmStopMatch(BuildContext context, GameModel game) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Stop & Complete Match: ${game.title}',
            style: TextStyle(color: context.textPrimary)),
        content: const Text(
            'Are you sure you want to stop this match? The match will be marked as COMPLETED and moved to Match History, where you can record the final score.',
            style: TextStyle(fontSize: 12.5)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Get.back();
              controller.completeGame(
                  game.id, game.teamAScore, game.teamBScore);
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
    DateTime selectedDate =
        DateTime.tryParse(game.matchDate) ?? DateTime.now();
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
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
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
                      hintStyle: TextStyle(
                          color: context.textSecondary, fontSize: 12),
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
