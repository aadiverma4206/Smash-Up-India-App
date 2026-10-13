import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';
import '../controllers/cctv_live_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';

class CctvLiveView extends GetView<CctvLiveController> {
  const CctvLiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Obx(() => Text(
              'Live CCTV - Camera ${controller.selectedChannel.value}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Stream Type (Main HD vs Sub SD) Toggle
          Obx(() => TextButton.icon(
                onPressed: controller.toggleStreamType,
                icon: Icon(
                  Icons.hd_rounded,
                  size: 18,
                  color: controller.streamType.value == 'main'
                      ? AppColors.primary
                      : Colors.grey,
                ),
                label: Text(
                  controller.streamType.value == 'main' ? 'HD' : 'SD',
                  style: TextStyle(
                    color: controller.streamType.value == 'main'
                        ? AppColors.primary
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )),
          // Manual Reconnect Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
                  aspectRatio: isFS ? (MediaQuery.of(context).size.width / MediaQuery.of(context).size.height) : (16 / 9),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: isFS
                          ? BorderRadius.zero
                          : BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade900,
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
                          _buildPlayerContent(context),

                          // Top-Left Live Status Overlay Badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _buildLiveStatusBadge(context),
                          ),

                          // Top-Right Fullscreen Toggle Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                isFS
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: controller.toggleFullscreen,
                            ),
                          ),

                          // Bottom-Left Camera Channel Info Banner
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Dahua XVR • Channel ${controller.selectedChannel.value}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
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

                // 2. Selectable 4 Camera Channels Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Camera Channel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '4 Channels Available',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Grid of 4 Selectable Camera Cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.45,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final channel = index + 1;
                        final isSelected =
                            controller.selectedChannel.value == channel;
                        final status = controller.channelStatuses[channel] ??
                            'Connecting';

                        return _buildCameraCard(
                            context, channel, isSelected, status);
                      },
                    ),
                  ),
                ),

                // Security & Network Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🔐 Server-managed credentials. Local DVR IP (192.168.1.2) requires court Wi-Fi or VPN connection.',
                          style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.3),
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

  Widget _buildPlayerContent(BuildContext context) {
    if (controller.isPlayerInitializing.value) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(message: ''),
          const SizedBox(height: 12),
          Text(
            'Connecting to Camera ${controller.selectedChannel.value} RTSP stream...',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      );
    }

    if (controller.vlcPlayerController != null && controller.isPlaying.value) {
      return VlcPlayer(
        controller: controller.vlcPlayerController!,
        aspectRatio: 16 / 9,
        placeholder: const AppLoader(message: 'Decoding RTSP stream...'),
      );
    }

    // Offline / Connection Failed State
    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'Camera ${controller.selectedChannel.value} ${controller.channelStatuses[controller.selectedChannel.value] ?? "Offline"}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            controller.errorMessage.value.isNotEmpty
                ? controller.errorMessage.value
                : 'Unable to establish RTSP stream connection to 192.168.1.2:554.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: controller.reconnectCurrentCamera,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusBadge(BuildContext context) {
    final status =
        controller.channelStatuses[controller.selectedChannel.value] ??
            'Connecting';

    Color color = Colors.orange;
    if (status == 'Live') {
      color = Colors.green;
    } else if (status == 'Offline' || status == 'Connection failed') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(
      BuildContext context, int channel, bool isSelected, String status) {
    Color statusColor = Colors.orange;
    if (status == 'Live') {
      statusColor = Colors.green;
    } else if (status == 'Offline' || status == 'Connection failed') {
      statusColor = Colors.red;
    }

    final courtName = channel % 2 != 0 ? 'Court 1 (Main Pitch)' : 'Court 2 (Side Pitch)';

    return InkWell(
      onTap: () => controller.selectCamera(channel),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
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
                        : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CH $channel',
                    style: const TextStyle(
                      color: Colors.white,
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
                  'Camera $channel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  courtName,
                  style: const TextStyle(
                    color: Colors.grey,
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
