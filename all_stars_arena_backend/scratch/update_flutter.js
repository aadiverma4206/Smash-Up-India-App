import fs from 'fs';
import path from 'path';

// 1. Update manager_games_controller.dart
const ctrlPath = path.resolve('../lib/modules/manager/controllers/manager_games_controller.dart');
let ctrlContent = fs.readFileSync(ctrlPath, 'utf8');

if (!ctrlContent.includes('import \'../../../data/models/video_model.dart\';')) {
  ctrlContent = ctrlContent.replace(
    "import '../../../data/models/game_model.dart';",
    "import '../../../data/models/game_model.dart';\nimport '../../../data/models/video_model.dart';\nimport '../../games/repositories/games_repository.dart';"
  );
}

if (!ctrlContent.includes('final RxList<VideoModel> matchVideos')) {
  ctrlContent = ctrlContent.replace(
    "  // CCTV playback URL\n  final RxnString cctvPlaybackUrl = RxnString();",
    "  // CCTV playback URL & Dynamic Multi-Camera Videos\n  final RxnString cctvPlaybackUrl = RxnString();\n  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;\n  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();\n  final RxBool isLoadingVideos = false.obs;"
  );
}

const oldFetchIdx = ctrlContent.indexOf('Future<void> fetchMatchRecording(String gameId) async {');
if (oldFetchIdx !== -1) {
  const endFetchIdx = ctrlContent.indexOf('  /// Manager approves player-created game request', oldFetchIdx);
  if (endFetchIdx !== -1) {
    const newFetchCode = `Future<void> fetchMatchRecording(String gameId) async {
    if (gameId.isEmpty) return;
    isLoadingVideos.value = true;
    try {
      final res = await repository.getMatchRecording(gameId);
      final List<dynamic>? vidsRaw = res['videos'] as List<dynamic>?;
      final List<VideoModel> parsedVideos = [];

      if (vidsRaw != null && vidsRaw.isNotEmpty) {
        for (final v in vidsRaw) {
          if (v is Map<String, dynamic>) {
            parsedVideos.add(VideoModel.fromJson(v));
          }
        }
      }

      if (parsedVideos.isEmpty) {
        try {
          if (Get.isRegistered<GamesRepository>()) {
            final fallbackVideos = await Get.find<GamesRepository>().getGameVideos(gameId);
            parsedVideos.addAll(fallbackVideos);
          }
        } catch (_) {}
      }

      matchVideos.assignAll(parsedVideos);

      if (matchVideos.isNotEmpty) {
        final currentId = selectedVideo.value?.id;
        final matching = matchVideos.firstWhereOrNull((v) => v.id == currentId);
        selectedVideo.value = matching ?? matchVideos.first;
        cctvPlaybackUrl.value = selectedVideo.value?.playbackUrl ?? matchVideos.first.playbackUrl;
      } else {
        selectedVideo.value = null;
        final url = res['playbackUrl'] ?? res['url'] ?? res['video_playback_url'];
        if (url != null && url.toString().isNotEmpty) {
          cctvPlaybackUrl.value = url.toString();
        }
      }
    } catch (e) {
      AppLogger.warning('Error fetching match CCTV recording: ' + e.toString());
    } finally {
      isLoadingVideos.value = false;
    }
  }

  void selectCamera(VideoModel video) {
    selectedVideo.value = video;
    if (video.playbackUrl.isNotEmpty) {
      cctvPlaybackUrl.value = video.playbackUrl;
    }
  }

  `;

    ctrlContent = ctrlContent.slice(0, oldFetchIdx) + newFetchCode + ctrlContent.slice(endFetchIdx);
    fs.writeFileSync(ctrlPath, ctrlContent, 'utf8');
    console.log('Successfully updated manager_games_controller.dart');
  }
}
