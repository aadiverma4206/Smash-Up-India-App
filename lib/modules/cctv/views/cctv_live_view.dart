import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:get/get.dart';
import '../controllers/cctv_live_controller.dart';
import '../../../data/models/cctv_models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';

class CctvLiveView extends StatelessWidget {
  const CctvLiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CctvLiveController>()
        ? Get.find<CctvLiveController>()
        : Get.put(CctvLiveController());

    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(
              'Live CCTV - Camera ${controller.selectedChannel.value}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            )),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            (isDark ? AppColors.darkAppBar : AppColors.sageGreenAppBar),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          // Stream Type (Main HD vs Sub SD) Toggle
          Obx(() => TextButton.icon(
                onPressed: controller.toggleStreamType,
                icon: Icon(
                  Icons.hd_rounded,
                  size: 18,
                  color: controller.streamType.value == 'main'
                      ? AppColors.primary
                      : (isDark ? Colors.grey : Colors.grey.shade700),
                ),
                label: Text(
                  controller.streamType.value == 'main' ? 'HD (Main)' : 'SD (Sub)',
                  style: TextStyle(
                    color: controller.streamType.value == 'main'
                        ? AppColors.primary
                        : (isDark ? Colors.grey : Colors.grey.shade700),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )),
          // Manual Reconnect Button
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: 'Reconnect Camera',
            onPressed: controller.reconnectCurrentCamera,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final isFS = controller.isFullscreen.value;

          return Column(
            children: [
              // 1. Live Video Player Display Frame
              Expanded(
                flex: isFS ? 1 : 0,
                child: AspectRatio(
                  aspectRatio: isFS
                      ? (MediaQuery.of(context).size.width /
                          MediaQuery.of(context).size.height)
                      : (16 / 9),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: isFS
                          ? BorderRadius.zero
                          : BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade900 : Colors.black26,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: isFS
                          ? BorderRadius.zero
                          : BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPlayerContent(context, controller, isFS),

                          // Top-Left Live Status & 3-Min Timer Overlay Badges
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLiveStatusBadge(context, controller),
                                const SizedBox(width: 8),
                                _buildViewingTimerBadge(context, controller),
                              ],
                            ),
                          ),

                          // Top-Right Fullscreen Toggle Button
                          Positioned(
                            top: 6,
                            right: 6,
                            child: IconButton(
                              icon: Icon(
                                isFS
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: controller.toggleFullscreen,
                            ),
                          ),

                          // Bottom-Left Camera Channel Info Banner
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Direct RTSP • Channel ${controller.selectedChannel.value} (${controller.streamType.value.toUpperCase()})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (!isFS) ...[
                const SizedBox(height: 16),

                // 2. Selectable Dynamic Camera Channels Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Camera Channel',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${controller.cameraOptions.length} Channels Available',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Grid of Selectable Camera Cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: controller.cameraOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.45,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final cam = controller.cameraOptions[index];
                        final isSelected =
                            controller.selectedChannel.value == cam.channel;
                        final status = controller.channelStatuses[cam.channel] ??
                            cam.status;

                        return _buildCameraCard(
                            context, controller, cam, isSelected, status);
                      },
                    ),
                  ),
                ),

                // Security & Network Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : context.inputBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🔒 Direct RTSP Stream • Auto-pauses after 3 minutes to preserve phone battery & camera network bandwidth.',
                          style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPlayerContent(
      BuildContext context, CctvLiveController controller, bool isFS) {
    if (controller.isViewingTimedOut.value) {
      return Container(
        color: const Color(0xFF151515),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_off_rounded,
                size: 38,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 8),
              const Text(
                'Live Stream Paused (3-Min Limit)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Paused automatically to save phone battery & camera network bandwidth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: controller.resumeStream,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('RESUME STREAM',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.videoController != null) {
      return SizedBox.expand(
        child: Video(
          key: ValueKey('media_kit_${controller.selectedChannel.value}_${controller.streamType.value}_${controller.videoController.hashCode}'),
          controller: controller.videoController!,
          fit: BoxFit.cover,
          controls: NoVideoControls,
        ),
      );
    }

    if (controller.isPlayerInitializing.value) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(message: ''),
          const SizedBox(height: 10),
          Text(
            'Connecting to Camera ${controller.selectedChannel.value} RTSP stream...',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    // Offline / Connection Failed State
    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 28),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                size: 32,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                'Camera ${controller.selectedChannel.value} ${controller.channelStatuses[controller.selectedChannel.value] ?? "Offline"}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'Unable to establish RTSP stream connection to camera.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (controller.streamType.value == 'main')
                    ElevatedButton.icon(
                      onPressed: controller.toggleStreamType,
                      icon: const Icon(Icons.sd_rounded, size: 14),
                      label: const Text('Use Sub Stream (SD)',
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: controller.reconnectCurrentCamera,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry Connection',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusBadge(
      BuildContext context, CctvLiveController controller) {
    final status =
        controller.channelStatuses[controller.selectedChannel.value] ??
            'Connecting';

    Color color = Colors.orange;
    if (status == 'Live' || status == 'ONLINE') {
      color = Colors.green;
    } else if (status == 'Offline' || status == 'Connection failed') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewingTimerBadge(
      BuildContext context, CctvLiveController controller) {
    final secs = controller.remainingViewingSeconds.value;
    final mins = (secs / 60).floor();
    final remaining = secs % 60;
    final timeStr =
        '${mins.toString().padLeft(2, "0")}:${remaining.toString().padLeft(2, "0")}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(
      BuildContext context,
      CctvLiveController controller,
      CctvLiveCameraOptionModel cam,
      bool isSelected,
      String status) {
    final isDark = context.isDark;
    final channel = cam.channel;

    Color statusColor = Colors.orange;
    if (status == 'Live' || status == 'ONLINE') {
      statusColor = Colors.green;
    } else if (status == 'Offline' || status == 'Connection failed') {
      statusColor = Colors.red;
    }

    final courtName =
        cam.courtName ?? (channel % 2 != 0 ? 'Court 1 (Main Pitch)' : 'Court 2 (Side Pitch)');

    return InkWell(
      onTap: () {
        if (controller.selectedChannel.value != channel ||
            controller.player == null ||
            controller.isViewingTimedOut.value) {
          controller.selectCamera(channel);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
              : context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CH $channel',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cam.name,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  courtName,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
