import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_roster_player_view.dart';
import '../controllers/game_details_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';

class GameDetailsView extends StatelessWidget {
  const GameDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GameDetailsController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              _buildRosterSection(context, controller, game),
              const SizedBox(height: 16),
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
    final totalFee = game.entryFee > 0 ? game.entryFee : game.perPlayerFee;

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
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 13),
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

  Widget _buildRosterSection(
      BuildContext context, GameDetailsController controller, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final teamARoster = controller.teamARoster;
      final teamBRoster = controller.teamBRoster;
      final totalJoined = teamARoster.length + teamBRoster.length;
      final activeTab = controller.activeRosterTab.value;
      final currentList = activeTab == 'TEAM_A' ? teamARoster : teamBRoster;
      final canManage = controller.canHostManageRoster;

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roster Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Joined Players Roster',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalJoined / ${game.maxPlayers} Players',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Team A / Team B Segment Filter Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRosterTeamTab(
                      context,
                      controller,
                      teamKey: 'TEAM_A',
                      label: 'TEAM A (${teamARoster.length})',
                      activeColor: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildRosterTeamTab(
                      context,
                      controller,
                      teamKey: 'TEAM_B',
                      label: 'TEAM B (${teamBRoster.length})',
                      activeColor: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Host Add Player Action Button
            if (canManage) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: activeTab == 'TEAM_A'
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFEF4444),
                    side: BorderSide(
                      color: activeTab == 'TEAM_A'
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFEF4444),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => Get.to(
                    () => AddRosterPlayerView(targetTeam: activeTab),
                    transition: Transition.cupertino,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    '+ Add Player to ${activeTab == 'TEAM_A' ? 'Team A' : 'Team B'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Player Cards List
            if (currentList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No players assigned to ${activeTab == 'TEAM_A' ? 'Team A' : 'Team B'} yet.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = currentList[index];
                  final isTeamA = activeTab == 'TEAM_A';
                  final teamColor = isTeamA
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFEF4444);
                  final resolvedAvatar =
                      player.profileImageUrl.resolvedImageUrl;

                  return TweenAnimationBuilder<double>(
                    key: ValueKey(player.userId),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 250 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: teamColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Player Profile Photo / Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: teamColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: resolvedAvatar.isValidNetworkUrl
                                  ? CachedNetworkImage(
                                      imageUrl: resolvedAvatar!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color:
                                            teamColor.withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            player.name.isNotEmpty
                                                ? player.name[0].toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              color: teamColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color:
                                            teamColor.withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            player.name.isNotEmpty
                                                ? player.name[0].toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              color: teamColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: teamColor.withValues(alpha: 0.15),
                                      child: Center(
                                        child: Text(
                                          player.name.isNotEmpty
                                              ? player.name[0].toUpperCase()
                                              : 'P',
                                          style: TextStyle(
                                            color: teamColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Player Name & Mobile Number
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                if (player.phone != null &&
                                    player.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '📞 ${player.phone}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Position Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: teamColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              player.position,
                              style: TextStyle(
                                color: teamColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Host Remove Icon Button (Host cannot remove themselves)
                          if (canManage && player.userId != game.creatorId) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20),
                              tooltip: 'Remove from Roster',
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'Remove Player',
                                  middleText:
                                      'Remove ${player.name} from ${isTeamA ? 'Team A' : 'Team B'} roster?',
                                  textConfirm: 'Yes, Remove',
                                  textCancel: 'Cancel',
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.redAccent,
                                  onConfirm: () {
                                    Get.back();
                                    controller.removePlayerFromRosterByHost(
                                        player.userId);
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildRosterTeamTab(
    BuildContext context,
    GameDetailsController controller, {
    required String teamKey,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = controller.activeRosterTab.value == teamKey;

    return InkWell(
      onTap: () => controller.activeRosterTab.value = teamKey,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : context.textSecondary,
          ),
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
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Match completed! CCTV recording is being processed and will be available shortly.',
                          style: TextStyle(
                              fontSize: 12, color: context.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: EmptyStateWidget(
                    title: 'No CCTV Footage Available',
                    subtitle:
                        'Footage will be automatically recorded and displayed here once available.',
                    icon: Icons.videocam_off_outlined,
                  ),
                ),
            ],
          ),
        );
      }

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
                Row(
                  children: [
                    const Icon(Icons.videocam_rounded,
                        color: AppColors.primary, size: 20),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${videos.isNotEmpty ? videos.length : 1} CAMERA',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (videos.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: videos.map((vid) {
                    final isSel = selectedVid?.id == vid.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(vid.cameraName),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: context.backgroundColor,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : context.textPrimary,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        onSelected: (sel) {
                          if (sel) controller.selectCamera(vid);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                    'videoUrl': rawVideoUrl,
                    'playbackUrl': rawVideoUrl,
                    'title':
                        '${game.title} - ${selectedVid?.cameraName ?? "CCTV Footage"}',
                    'cameras': videos.map((v) => v.toJson()).toList(),
                    'initialIndex':
                        videos.indexWhere((v) => v.id == selectedVid?.id),
                  });
                },
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                label: Text(
                  'Recorded Match Video ${selectedVid?.cameraName ?? "Main"}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
