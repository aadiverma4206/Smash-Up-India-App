import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_player_controller.dart';
import '../../../app/theme/app_colors.dart';

class VideoPlayerView extends GetView<VideoPlayerController> {
  const VideoPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.title.value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Multi-camera quick switcher inside player view
              Obx(() {
                if (controller.cameras.length <= 1)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(controller.cameras.length, (idx) {
                        final cam = controller.cameras[idx];
                        final isSel =
                            controller.selectedCameraIndex.value == idx;
                        final name = (cam['cameraName'] ?? 'Camera ${idx + 1}')
                            .toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => controller.switchCamera(idx),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary
                                    : const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.primary
                                      : Colors.grey.shade700,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.videocam_rounded,
                                      size: 14,
                                      color:
                                          isSel ? Colors.white : Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color:
                                          isSel ? Colors.white : Colors.white70,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
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
                );
              }),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Obx(
                  () => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.isPlaying.value
                            ? 'Streaming S3 Match Video...'
                            : 'Tap Play to start streaming',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.togglePlay,
                  icon: Icon(controller.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow),
                  label: Text(controller.isPlaying.value
                      ? 'Pause Stream'
                      : 'Start S3 Signed Stream'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🔐 Playback URL is short-lived and authorized by backend.\nS3 credentials and RTSP streams are never exposed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
