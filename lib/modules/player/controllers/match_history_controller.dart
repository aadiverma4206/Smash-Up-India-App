import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/player_repository.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/video_model.dart';
import '../../games/repositories/games_repository.dart';
import '../../../core/utils/app_logger.dart';

class MatchHistoryController extends GetxController {
  final PlayerRepository repository = Get.find<PlayerRepository>();

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  final RxList<GameModel> historyGames = <GameModel>[].obs;
  final Rxn<GameModel> selectedGame = Rxn<GameModel>();
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearchingOrFiltering = false.obs;
  final RxBool isOfflineMode = false.obs;
  final RxBool hasMore = true.obs;
  final RxString activeFilter = 'ALL'.obs;
  final RxString selectedRosterTeamFilter = 'TEAM_A'.obs;
  int currentOffset = 0;
  final int limit = 20;

  final RxnString cctvPlaybackUrl = RxnString();
  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;
  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();
  final RxBool isLoadingVideos = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory(isRefresh: true);
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        fetchHistory(isRefresh: false);
      }
    }
  }

  Future<void> fetchHistory({bool isRefresh = true}) async {
    if (isRefresh) {
      currentOffset = 0;
      hasMore.value = true;
      isSearchingOrFiltering.value = true;
    }
    if (!hasMore.value && !isRefresh) return;

    isLoadingMore.value = true;

    try {
      final list = await repository.getHistory(
        limit: limit,
        offset: currentOffset,
        status: activeFilter.value,
      );
      if (list.length < limit) {
        hasMore.value = false;
      }
      if (isRefresh) {
        historyGames.assignAll(list);
      } else {
        historyGames.addAll(list);
      }
      currentOffset += list.length;
      isOfflineMode.value = false;
    } catch (e) {
      AppLogger.warning('Error fetching player history: $e');
      if (historyGames.isNotEmpty) {
        isOfflineMode.value = true;
      }
    } finally {
      isLoadingMore.value = false;
      isSearchingOrFiltering.value = false;
    }
  }

  List<GameModel> get filteredHistoryGames {
    final query = searchController.text.trim().toLowerCase();
    return historyGames.where((game) {
      if (query.isNotEmpty) {
        final title = game.title.toLowerCase();
        final court = game.courtName.toLowerCase();
        final format = game.format.toLowerCase();
        if (!title.contains(query) &&
            !court.contains(query) &&
            !format.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> fetchMatchRecording(String gameId) async {
    isLoadingVideos.value = true;
    try {
      if (Get.isRegistered<GamesRepository>()) {
        final videos = await Get.find<GamesRepository>().getGameVideos(gameId);
        matchVideos.assignAll(videos);
        if (matchVideos.isNotEmpty) {
          selectedVideo.value = matchVideos.first;
          cctvPlaybackUrl.value = matchVideos.first.playbackUrl;
        }
      }
    } catch (e) {
      AppLogger.warning('Error fetching player match CCTV: $e');
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
}
