import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_details_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/app_date_utils.dart';

class GameDetailsView extends StatelessWidget {
  const GameDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GameDetailsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadGameDetails,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoader(message: 'Loading booking details...');
        }
        final game = controller.game.value;
        if (game == null) {
          return const Center(
              child: Text('Booking not found',
                  style: TextStyle(color: Colors.white)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingInfoCard(context, game),
              const SizedBox(height: 16),
              _buildScoreboardCard(context, game),
              _buildHostCancelCard(context, controller, game),
              const SizedBox(height: 20),
              _buildVideoSection(context, controller, game),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBookingInfoCard(BuildContext context, GameModel game) {
    final totalFee =
        game.entryFee > 0 ? game.entryFee : game.perPlayerFee;

    return Card(
      color: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    game.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.status.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.stadium_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${game.clubName} • ${game.courtName}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${AppDateUtils.formatDate(game.matchDate)} • ${AppDateUtils.formatTimeRange(game.startTime, game.endTime)}',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.currency_rupee_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pitch Booking Fee: ₹${totalFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (game.description != null && game.description!.isNotEmpty) ...[
              Divider(color: context.borderColor, height: 24),
              Text(
                'Notes / Guidelines: ${game.description}',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostCancelCard(
      BuildContext context, GameDetailsController controller, GameModel game) {
    if (!controller.canHostCancel) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Manage Booking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'As the booking creator, you can cancel this pitch reservation. Refund will be processed as per arena policy.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Get.defaultDialog(
                  title: 'Cancel Pitch Booking',
                  middleText: 'Are you sure you want to cancel this booking?',
                  textConfirm: 'Yes, Cancel',
                  textCancel: 'No, Keep',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () {
                    Get.back();
                    controller.cancelMatchByHost('Host requested cancellation');
                  },
                );
              },
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('Cancel Pitch Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(
      BuildContext context, GameDetailsController controller, GameModel game) {
    return Obx(() {
      final videos = controller.matchVideos;
      final selectedVid = controller.selectedVideo.value;
      final rawVideoUrl = selectedVid?.playbackUrl ?? game.videoPlaybackUrl;

      if (rawVideoUrl == null || rawVideoUrl.isEmpty) {
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
                  const Icon(Icons.videocam_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CCTV Recorded Footage',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (game.status.toUpperCase() == 'COMPLETED')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Match Video Processing',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Full match recording will be available in the app 10 minutes after match completion.',
                              style: TextStyle(
                                  color: context.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const EmptyStateWidget(
                  title: 'No CCTV Footage Available',
                  subtitle:
                      'Footage will be automatically recorded and displayed here once available.',
                  imageSize: 130,
                ),
            ],
          ),
        );
      }

      final videoUrl = rawVideoUrl;
      final cameraName = selectedVid?.cameraName ?? 'Camera 1';
      final isManagerOrAdmin =
          AuthService.to.isManager || AuthService.to.isAdmin;
      final showMultiCam = isManagerOrAdmin && videos.length > 1;

      return Column(
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
                    'CCTV Recorded Footage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              if (showMultiCam)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${videos.length} CAMERAS',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (showMultiCam) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(videos.length, (index) {
                  final vid = videos[index];
                  final isSelected = selectedVid?.id == vid.id ||
                      (selectedVid == null && index == 0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: InkWell(
                      onTap: () => controller.selectCamera(vid),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : context.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.videocam_rounded,
                                size: 14,
                                color: isSelected ? Colors.white : Colors.grey),
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
            const SizedBox(height: 6),
          ],
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded,
                      size: 60, color: AppColors.primary),
                  onPressed: () {
                    Get.toNamed('/videos/player', arguments: {
                      'videoUrl': videoUrl,
                      'title': '${game.title} - $cameraName',
                      'cameras': videos.map((v) => v.toJson()).toList(),
                      'initialIndex':
                          videos.indexWhere((v) => v.id == selectedVid?.id),
                    });
                  },
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${game.courtName} • $cameraName • Auto-recorded CCTV Video',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Get.toNamed('/videos/player', arguments: {
                  'videoUrl': videoUrl,
                  'title': '${game.title} - $cameraName',
                  'cameras': videos.map((v) => v.toJson()).toList(),
                  'initialIndex':
                      videos.indexWhere((v) => v.id == selectedVid?.id),
                });
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                isManagerOrAdmin
                    ? 'Watch Recorded Match Video ($cameraName)'
                    : 'Watch Recorded Match Video',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScoreboardCard(BuildContext context, GameModel game) {
    final isOngoing = game.status == 'ONGOING';
    final isCompleted = game.status == 'COMPLETED';
    final hasScore = isOngoing || isCompleted || game.teamAScore > 0 || game.teamBScore > 0;
    if (!hasScore) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winner = game.winnerTeam;

    String winnerText = '';
    Color winnerColor = AppColors.primary;
    if (isCompleted) {
      if (winner == 'TEAM_A' || game.teamAScore > game.teamBScore) {
        winnerText = '🏆 Team A Won the Match';
        winnerColor = const Color(0xFF10B981);
      } else if (winner == 'TEAM_B' || game.teamBScore > game.teamAScore) {
        winnerText = '🏆 Team B Won the Match';
        winnerColor = const Color(0xFF10B981);
      } else {
        winnerText = '🤝 Match Ended in a Draw';
        winnerColor = Colors.amber.shade700;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF17231B), const Color(0xFF0F1713)]
              : [const Color(0xFFF0FDF4), const Color(0xFFE8F5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOngoing
              ? Colors.redAccent.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOngoing ? Colors.redAccent : AppColors.primary)
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isOngoing) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE SCORE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'FINAL SCORE',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOngoing ? Colors.redAccent : Colors.green)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOngoing ? 'MATCH IN PROGRESS' : 'MATCH COMPLETED',
                  style: TextStyle(
                    color: isOngoing ? Colors.redAccent : Colors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TEAM A',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${game.teamAScore}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TEAM B',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${game.teamBScore}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (winnerText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: winnerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                winnerText,
                style: TextStyle(
                  color: winnerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
