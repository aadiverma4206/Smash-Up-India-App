import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as vp;
import '../controllers/video_player_controller.dart';
import '../../../app/theme/app_colors.dart';

class VideoPlayerView extends GetView<VideoPlayerController> {
  const VideoPlayerView({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';
    return '$hours$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Obx(() => Text(
              controller.title.value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.isDownloading.value) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: controller.downloadProgress.value > 0
                        ? controller.downloadProgress.value
                        : null,
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              );
            }
            if (controller.isDownloaded.value) {
              return IconButton(
                icon: const Icon(Icons.download_done_rounded,
                    color: Colors.green),
                tooltip: 'Saved to device',
                onPressed: () {
                  Get.snackbar('Saved Offline',
                      'This match recording is saved to local storage.');
                },
              );
            }
            return IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white70),
              tooltip: 'Download match recording',
              onPressed: controller.downloadVideo,
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (controller.cameras.length <= 1) {
                return const SizedBox.shrink();
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: const Color(0xFF111111),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(controller.cameras.length, (idx) {
                      final cam = controller.cameras[idx];
                      final isSel = controller.selectedCameraIndex.value == idx;
                      final name =
                          (cam['cameraName'] ?? 'Camera ${idx + 1}').toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(Icons.videocam_rounded,
                              size: 14,
                              color: isSel ? Colors.white : Colors.grey),
                          label: Text(
                            name,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.white70,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFF222222),
                          onSelected: (_) => controller.switchCamera(idx),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
            Expanded(
              child: Center(
                child: Obx(() {
                  if (controller.hasError.value) {
                    return Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Playback Error',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: controller.retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!controller.isInitialized.value) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Buffering Match CCTV Stream...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    );
                  }

                  final vpController = controller.videoPlayerController!;

                  return GestureDetector(
                    onTap: controller.toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: vpController.value.aspectRatio > 0
                              ? vpController.value.aspectRatio
                              : 16 / 9,
                          child: vp.VideoPlayer(vpController),
                        ),
                        if (controller.isBuffering.value)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          ),
                        AnimatedOpacity(
                          opacity:
                              controller.isControlsVisible.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            color: Colors.black38,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      iconSize: 38,
                                      icon: const Icon(Icons.replay_10_rounded,
                                          color: Colors.white),
                                      onPressed: controller.seekBackward10,
                                    ),
                                    const SizedBox(width: 24),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        iconSize: 46,
                                        icon: Icon(
                                          controller.isPlaying.value
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: controller.togglePlay,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      iconSize: 38,
                                      icon: const Icon(Icons.forward_10_rounded,
                                          color: Colors.white),
                                      onPressed: controller.seekForward10,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black87,
                                        Colors.transparent
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _formatDuration(controller
                                                .currentPosition.value),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                trackHeight: 3.5,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                        enabledThumbRadius:
                                                            6.5),
                                                activeTrackColor:
                                                    AppColors.primary,
                                                inactiveTrackColor:
                                                    Colors.white24,
                                                thumbColor: AppColors.primary,
                                              ),
                                              child: Slider(
                                                value: controller
                                                    .currentPosition
                                                    .value
                                                    .inMilliseconds
                                                    .clamp(
                                                        0,
                                                        controller
                                                            .totalDuration
                                                            .value
                                                            .inMilliseconds)
                                                    .toDouble(),
                                                min: 0.0,
                                                max: controller
                                                            .totalDuration
                                                            .value
                                                            .inMilliseconds
                                                            .toDouble() >
                                                        0
                                                    ? controller.totalDuration
                                                        .value.inMilliseconds
                                                        .toDouble()
                                                    : 1.0,
                                                onChanged: (val) {
                                                  controller.seekTo(Duration(
                                                      milliseconds:
                                                          val.toInt()));
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(
                                                controller.totalDuration.value),
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(
                                              controller.isFullScreen.value
                                                  ? Icons
                                                      .fullscreen_exit_rounded
                                                  : Icons.fullscreen_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                controller.toggleFullScreen,
                                          ),
                                        ],
                                      ),
                                    ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
