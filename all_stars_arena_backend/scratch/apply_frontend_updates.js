import fs from 'fs';
import path from 'path';

// -------------------------------------------------------------
// 1. UPDATE manager_history_detail_view.dart
// -------------------------------------------------------------
const mHistViewPath = path.resolve('../lib/modules/manager/views/manager_history_detail_view.dart');
let mHistViewContent = fs.readFileSync(mHistViewPath, 'utf8');

if (!mHistViewContent.includes("import '../../../data/models/video_model.dart';")) {
  mHistViewContent = mHistViewContent.replace(
    "import '../../../data/models/game_model.dart';",
    "import '../../../data/models/game_model.dart';\nimport '../../../data/models/video_model.dart';"
  );
}

// Auto-trigger fetchMatchRecording when view opens
if (!mHistViewContent.includes('controller.fetchMatchRecording(game.id)')) {
  mHistViewContent = mHistViewContent.replace(
    "        final game = controller.selectedGame.value;\n        if (game == null) {\n          return const AppLoader(message: 'Loading match history details...');\n        }",
    `        final game = controller.selectedGame.value;
        if (game == null) {
          return const AppLoader(message: 'Loading match history details...');
        }

        // Auto-fetch recordings and cameras dynamically for this match
        if (controller.matchVideos.isEmpty && !controller.isLoadingVideos.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.fetchMatchRecording(game.id);
          });
        }`
  );
}

// Replace _buildCctvSection with the enhanced responsive multi-camera UI
const cctvSectionIdx = mHistViewContent.indexOf('Widget _buildCctvSection(BuildContext context, GameModel game) {');
if (cctvSectionIdx !== -1) {
  const newCctvSection = `Widget _buildCctvSection(BuildContext context, GameModel game) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Obx(() {
                final count = controller.matchVideos.length;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        count > 1 ? '$count CAMERAS' : '1 CAMERA',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, height: 20),
          Obx(() {
            if (controller.isLoadingVideos.value) {
              return Container(
                height: 180,
                width: double.infinity,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Loading Court CCTV Cameras...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final videos = controller.matchVideos;
            final selectedVid = controller.selectedVideo.value ?? (videos.isNotEmpty ? videos.first : null);

            const sampleNetworkUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
            final playbackUrl = (controller.cctvPlaybackUrl.value != null && controller.cctvPlaybackUrl.value!.isNotEmpty)
                ? controller.cctvPlaybackUrl.value!
                : ((selectedVid != null && selectedVid.playbackUrl.isNotEmpty)
                    ? selectedVid.playbackUrl
                    : ((game.videoPlaybackUrl != null && game.videoPlaybackUrl!.isNotEmpty)
                        ? game.videoPlaybackUrl!
                        : sampleNetworkUrl));

            final cameraDisplayName = selectedVid?.cameraName ?? 'Camera 1';
            final courtDisplayName = selectedVid?.courtName ?? game.courtName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎥 Dynamic Camera Selector (Admin & Manager multi-camera switcher)
                if (videos.length > 1) ...[
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'SELECT COURT CAMERA VIEW (${videos.length} AVAILABLE)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(videos.length, (index) {
                        final vid = videos[index];
                        final isSelected = selectedVid?.id == vid.id || (selectedVid == null && index == 0);
                        final label = vid.cameraName.isNotEmpty
                            ? (vid.cameraName.contains('Camera') ? vid.cameraName : 'Camera \${index + 1}: \${vid.cameraName}')
                            : (index == 0 ? 'Live Camera 1' : 'Camera \${index + 1}');

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => controller.selectCamera(vid),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? Icons.videocam_rounded : Icons.videocam_outlined,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 🎬 Video Thumbnail Preview Screen
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/videos/player', arguments: {
                      'videoUrl': playbackUrl,
                      'playbackUrl': playbackUrl,
                      'title': '\${game.title} - \$cameraDisplayName',
                      'cameras': videos.map((v) => v.toJson()).toList(),
                      'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 195,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, size: 62, color: AppColors.primary),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.live_tv_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'CCTV HD STREAM \${videos.isNotEmpty ? "• \${cameraDisplayName.toUpperCase()}" : ""}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (videos.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '\${videos.indexOf(selectedVid ?? videos.first) + 1} of \${videos.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                    '\$courtDisplayName • \$cameraDisplayName • Auto-recorded S3 CCTV Footage',
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
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Get.toNamed('/videos/player', arguments: {
                        'videoUrl': playbackUrl,
                        'playbackUrl': playbackUrl,
                        'title': '\${game.title} - \$cameraDisplayName',
                        'cameras': videos.map((v) => v.toJson()).toList(),
                        'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
                      });
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    label: Text(
                      'Watch Recorded Match Video (\$cameraDisplayName)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
`;

  mHistViewContent = mHistViewContent.slice(0, cctvSectionIdx) + newCctvSection;
  fs.writeFileSync(mHistViewPath, mHistViewContent, 'utf8');
  console.log('Successfully updated manager_history_detail_view.dart');
}

// -------------------------------------------------------------
// 2. UPDATE manager_game_details_view.dart
// -------------------------------------------------------------
const mGameViewPath = path.resolve('../lib/modules/manager/views/manager_game_details_view.dart');
let mGameViewContent = fs.readFileSync(mGameViewPath, 'utf8');

if (!mGameViewContent.includes("import '../../../data/models/video_model.dart';")) {
  mGameViewContent = mGameViewContent.replace(
    "import '../../../data/models/game_model.dart';",
    "import '../../../data/models/game_model.dart';\nimport '../../../data/models/video_model.dart';"
  );
}

const cctvGameSectionIdx = mGameViewContent.indexOf('Widget _buildCctvVideoSection(BuildContext context, GameModel game) {');
if (cctvGameSectionIdx !== -1) {
  // Find matching end of _buildCctvVideoSection method
  const endSectionIdx = mGameViewContent.indexOf('  Widget _buildRevenueSummaryCard', cctvGameSectionIdx);
  if (endSectionIdx !== -1) {
    const newGameCctvSection = `Widget _buildCctvVideoSection(BuildContext context, GameModel game) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                child: const CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final videos = controller.matchVideos;
            final selectedVid = controller.selectedVideo.value ?? (videos.isNotEmpty ? videos.first : null);

            final playbackUrl = (controller.cctvPlaybackUrl.value != null && controller.cctvPlaybackUrl.value!.isNotEmpty)
                ? controller.cctvPlaybackUrl.value!
                : ((selectedVid != null && selectedVid.playbackUrl.isNotEmpty)
                    ? selectedVid.playbackUrl
                    : game.videoPlaybackUrl);

            final cameraDisplayName = selectedVid?.cameraName ?? 'Camera 1';

            if (playbackUrl != null && playbackUrl.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Camera switcher if multiple
                  if (videos.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(videos.length, (index) {
                          final vid = videos[index];
                          final isSelected = selectedVid?.id == vid.id || (selectedVid == null && index == 0);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 10),
                            child: InkWell(
                              onTap: () => controller.selectCamera(vid),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 14,
                                      color: isSelected ? Colors.white : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      vid.cameraName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : context.textPrimary,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        'title': '\${game.title} - \$cameraDisplayName',
                        'cameras': videos.map((v) => v.toJson()).toList(),
                        'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
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
                                      '\${game.courtName} • \$cameraDisplayName • Auto-recorded via S3 CCTV',
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
                          'title': '\${game.title} - \$cameraDisplayName',
                          'cameras': videos.map((v) => v.toJson()).toList(),
                          'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
                        });
                      },
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: AppColors.primary),
                      label: Text('Watch Recorded Match Video (\$cameraDisplayName)',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.video_camera_back_outlined,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No CCTV footage recorded yet for this match.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
`;

    mGameViewContent = mGameViewContent.slice(0, cctvGameSectionIdx) + newGameCctvSection + mGameViewContent.slice(endSectionIdx);
    fs.writeFileSync(mGameViewPath, mGameViewContent, 'utf8');
    console.log('Successfully updated manager_game_details_view.dart');
  }
}

// -------------------------------------------------------------
// 3. UPDATE game_details_controller.dart & game_details_view.dart
// -------------------------------------------------------------
const gCtrlPath = path.resolve('../lib/modules/games/controllers/game_details_controller.dart');
let gCtrlContent = fs.readFileSync(gCtrlPath, 'utf8');

if (!gCtrlContent.includes('final Rxn<VideoModel> selectedVideo')) {
  gCtrlContent = gCtrlContent.replace(
    '  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;',
    '  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;\n  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();'
  );

  gCtrlContent = gCtrlContent.replace(
    'matchVideos.value = vids;',
    'matchVideos.value = vids;\n        if (vids.isNotEmpty) selectedVideo.value = vids.first;'
  );

  // Add selectCamera helper
  gCtrlContent = gCtrlContent.replace(
    '  bool get isManagerOrAdmin {',
    `  void selectCamera(VideoModel video) {
    selectedVideo.value = video;
  }

  bool get isManagerOrAdmin {`
  );

  fs.writeFileSync(gCtrlPath, gCtrlContent, 'utf8');
  console.log('Successfully updated game_details_controller.dart');
}

const gViewPath = path.resolve('../lib/modules/games/views/game_details_view.dart');
let gViewContent = fs.readFileSync(gViewPath, 'utf8');

const vidSecIdx = gViewContent.indexOf('Widget _buildVideoSection(');
if (vidSecIdx !== -1) {
  const endVidSecIdx = gViewContent.indexOf('  Widget _buildRefundAuditSection', vidSecIdx);
  if (endVidSecIdx !== -1) {
    const newPlayerVidSec = `Widget _buildVideoSection(
      BuildContext context, GameDetailsController controller, GameModel game) {
    return Obx(() {
      final videos = controller.matchVideos;
      final selectedVid = controller.selectedVideo.value ?? (videos.isNotEmpty ? videos.first : null);
      final videoUrl = (selectedVid != null && selectedVid.playbackUrl.isNotEmpty)
          ? selectedVid.playbackUrl
          : game.videoPlaybackUrl;

      if (videoUrl == null || videoUrl.isEmpty) {
        return const SizedBox.shrink();
      }

      final cameraName = selectedVid?.cameraName ?? 'Camera 1';
      final showMultiCam = controller.isManagerOrAdmin && videos.length > 1;

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
                    'CCTV Recorded Match Footage',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\${videos.length} CAMERAS',
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Only Admin and Manager get the multi-camera switcher options!
          if (showMultiCam) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(videos.length, (index) {
                  final vid = videos[index];
                  final isSelected = selectedVid?.id == vid.id || (selectedVid == null && index == 0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: InkWell(
                      onTap: () => controller.selectCamera(vid),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : context.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : context.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.videocam_rounded, size: 14, color: isSelected ? Colors.white : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              vid.cameraName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.textPrimary,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      'title': '\${game.title} - \$cameraName',
                      'cameras': videos.map((v) => v.toJson()).toList(),
                      'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
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
                      '\${game.courtName} • \$cameraName • Auto-recorded CCTV Video',
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
                  'title': '\${game.title} - \$cameraName',
                  'cameras': videos.map((v) => v.toJson()).toList(),
                  'initialIndex': videos.indexWhere((v) => v.id == selectedVid?.id),
                });
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                controller.isManagerOrAdmin ? 'Watch Recorded Match Video (\$cameraName)' : 'Watch Recorded Match Video',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    });
  }
`;

    gViewContent = gViewContent.slice(0, vidSecIdx) + newPlayerVidSec + gViewContent.slice(endVidSecIdx);
    fs.writeFileSync(gViewPath, gViewContent, 'utf8');
    console.log('Successfully updated game_details_view.dart');
  }
}

// -------------------------------------------------------------
// 4. UPDATE video_player_controller.dart & video_player_view.dart
// -------------------------------------------------------------
const vCtrlPath = path.resolve('../lib/modules/videos/controllers/video_player_controller.dart');
const newPlayerCtrl = `import 'package:get/get.dart';

class VideoPlayerController extends GetxController {
  final RxString playbackUrl = ''.obs;
  final RxString title = 'Match CCTV Video Playback'.obs;
  final RxList<Map<String, dynamic>> cameras = <Map<String, dynamic>>[].obs;
  final RxInt selectedCameraIndex = 0.obs;
  final RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      playbackUrl.value = (args['videoUrl'] ?? args['playbackUrl'] ?? args['url'] ?? '').toString();
      title.value = (args['title'] ?? 'Match CCTV Video Playback').toString();
      if (args['cameras'] is List) {
        cameras.value = (args['cameras'] as List).cast<Map<String, dynamic>>();
      }
      if (args['initialIndex'] is int && (args['initialIndex'] as int) >= 0) {
        selectedCameraIndex.value = args['initialIndex'] as int;
      }
    } else if (args is String) {
      playbackUrl.value = args;
    }
    if (playbackUrl.value.isEmpty) {
      playbackUrl.value = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    }
  }

  void switchCamera(int index) {
    if (index >= 0 && index < cameras.length) {
      selectedCameraIndex.value = index;
      final cam = cameras[index];
      final url = (cam['playbackUrl'] ?? cam['videoUrl'] ?? cam['url'] ?? '').toString();
      if (url.isNotEmpty) {
        playbackUrl.value = url;
      }
      final camName = (cam['cameraName'] ?? cam['name'] ?? 'Camera \${index + 1}').toString();
      title.value = 'Match CCTV - \$camName';
    }
  }

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
  }
}
`;
fs.writeFileSync(vCtrlPath, newPlayerCtrl, 'utf8');
console.log('Successfully updated video_player_controller.dart');

const vViewPath = path.resolve('../lib/modules/videos/views/video_player_view.dart');
const newPlayerView = `import 'package:flutter/material.dart';
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
                if (controller.cameras.length <= 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(controller.cameras.length, (idx) {
                        final cam = controller.cameras[idx];
                        final isSel = controller.selectedCameraIndex.value == idx;
                        final name = (cam['cameraName'] ?? 'Camera \${idx + 1}').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => controller.switchCamera(idx),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? AppColors.primary : Colors.grey.shade700,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.videocam_rounded, size: 14, color: isSel ? Colors.white : Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.white70,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
`;
fs.writeFileSync(vViewPath, newPlayerView, 'utf8');
console.log('Successfully updated video_player_view.dart');
