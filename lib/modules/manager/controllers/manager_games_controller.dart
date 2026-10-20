import 'package:get/get.dart';
import '../repositories/manager_repository.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/video_model.dart';
import '../../games/repositories/games_repository.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_date_utils.dart';

class ManagerGamesController extends GetxController {
  final ManagerRepository repository = Get.find<ManagerRepository>();

  final RxList<GameModel> games = <GameModel>[].obs;
  final Rxn<GameModel> selectedGame = Rxn<GameModel>();
  final RxBool isLoading = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'ALL'.obs;
  final RxString selectedCourtFilter = 'ALL'.obs;
  final Rxn<DateTime> customSelectedDate = Rxn<DateTime>();
  final RxString selectedRosterTeamFilter = 'TEAM_A'.obs;
  final RxList<GameRosterPlayerModel> teamAPlayers =
      <GameRosterPlayerModel>[].obs;
  final RxList<GameRosterPlayerModel> teamBPlayers =
      <GameRosterPlayerModel>[].obs;
  final RxBool isLoadingRoster = false.obs;

  final RxnString cctvPlaybackUrl = RxnString();
  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;
  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();
  final RxBool isLoadingVideos = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClubGames();
    final args = Get.arguments;
    if (args is Map) {
      if (args['game'] is GameModel) {
        selectedGame.value = args['game'] as GameModel;
      }
      final gameId = (args['gameId'] ?? args['id'] ?? selectedGame.value?.id ?? '').toString();
      if (gameId.isNotEmpty) {
        fetchMatchRecording(gameId);
        fetchGamePlayers(gameId);
      }
    } else if (args is GameModel) {
      selectedGame.value = args;
      fetchMatchRecording(args.id);
      fetchGamePlayers(args.id);
    }
  }

  Future<void> fetchGamePlayers(String gameId) async {
    if (gameId.isEmpty) return;
    isLoadingRoster.value = true;
    try {
      final res = await repository.getGamePlayers(gameId);
      final rawTeamA = res['teamA'] as List? ?? [];
      final rawTeamB = res['teamB'] as List? ?? [];
      final rawRoster = res['roster'] as List? ?? [];

      final aList = rawTeamA
          .map((e) => GameRosterPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final bList = rawTeamB
          .map((e) => GameRosterPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final fullRoster = rawRoster
          .map((e) => GameRosterPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      teamAPlayers.assignAll(aList);
      teamBPlayers.assignAll(bList);

      if (selectedGame.value != null && selectedGame.value!.id == gameId) {
        final cur = selectedGame.value!;
        selectedGame.value = GameModel(
          id: cur.id,
          title: cur.title,
          clubId: cur.clubId,
          clubName: cur.clubName,
          courtId: cur.courtId,
          courtName: cur.courtName,
          matchDate: cur.matchDate,
          startTime: cur.startTime,
          endTime: cur.endTime,
          status: cur.status,
          format: cur.format,
          perPlayerFee: cur.perPlayerFee,
          maxPlayers: cur.maxPlayers,
          currentPlayers:
              fullRoster.isNotEmpty ? fullRoster.length : cur.currentPlayers,
          skillRequirement: cur.skillRequirement,
          privacy: cur.privacy,
          creatorId: cur.creatorId,
          creatorRoleName: cur.creatorRoleName,
          createdByPlayer: cur.createdByPlayer,
          teamAScore: cur.teamAScore,
          teamBScore: cur.teamBScore,
          winnerTeam: cur.winnerTeam,
          userTeam: cur.userTeam,
          userPosition: cur.userPosition,
          description: cur.description,
          waitlistPosition: cur.waitlistPosition,
          roster: fullRoster,
          videoPlaybackUrl: cur.videoPlaybackUrl,
        );
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch game players: $e');
    } finally {
      isLoadingRoster.value = false;
    }
  }

  Future<void> fetchClubGames({String? court}) async {
    isLoading.value = true;
    try {
      final courtParam = court ??
          (selectedCourtFilter.value == 'ALL'
              ? null
              : selectedCourtFilter.value);
      final list = await repository.getClubGames(court: courtParam);
      games.assignAll(list);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
          'Scope Error', 'Forbidden: You can only access assigned club games');
    } finally {
      isLoading.value = false;
    }
  }

  void setCourtFilter(String court) {
    selectedCourtFilter.value = court;
    fetchClubGames(court: court == 'ALL' ? null : court);
  }

  List<GameModel> get filteredGames {
    return games.where((g) {
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        final titleMatches = g.title.toLowerCase().contains(q);
        final courtMatches = g.courtName.toLowerCase().contains(q);
        final formatMatches = g.format.toLowerCase().contains(q);
        final statusMatches = g.status.toLowerCase().contains(q);
        if (!titleMatches &&
            !courtMatches &&
            !formatMatches &&
            !statusMatches) {
          return false;
        }
      }

      final filter = selectedFilter.value;
      if (filter == 'TODAY') {
        final todayStr = AppDateUtils.formatIsoDate(DateTime.now());
        if (!g.matchDate.startsWith(todayStr)) return false;
      } else if (filter == 'TOMORROW') {
        final tmrwStr = AppDateUtils.formatIsoDate(
            DateTime.now().add(const Duration(days: 1)));
        if (!g.matchDate.startsWith(tmrwStr)) return false;
      } else if (filter == 'SELECT DATE') {
        if (customSelectedDate.value != null) {
          final customStr =
              AppDateUtils.formatIsoDate(customSelectedDate.value!);
          if (!g.matchDate.startsWith(customStr)) return false;
        }
      } else if (filter == 'ONGOING') {
        if (g.status != 'ONGOING' && g.status != 'STARTED') return false;
      } else if (filter == 'COMPLETED') {
        if (g.status != 'COMPLETED') return false;
      } else if (filter == 'CANCELLED') {
        if (g.status != 'CANCELLED') return false;
      }

      return true;
    }).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setCustomDate(DateTime date) {
    customSelectedDate.value = date;
    selectedFilter.value = 'SELECT DATE';
  }

  Future<void> fetchMatchRecording(String gameId) async {
    if (gameId.isEmpty) return;
    isLoadingVideos.value = true;
    matchVideos.clear();
    selectedVideo.value = null;
    cctvPlaybackUrl.value = null;
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
            final fallbackVideos =
                await Get.find<GamesRepository>().getGameVideos(gameId);
            parsedVideos.addAll(fallbackVideos);
          }
        } catch (_) {}
      }

      matchVideos.assignAll(parsedVideos);

      if (matchVideos.isNotEmpty) {
        final currentId = selectedVideo.value?.id;
        final matching = matchVideos.firstWhereOrNull((v) => v.id == currentId);
        selectedVideo.value = matching ?? matchVideos.first;
        cctvPlaybackUrl.value =
            selectedVideo.value?.playbackUrl ?? matchVideos.first.playbackUrl;
      } else {
        selectedVideo.value = null;
        final url =
            res['playbackUrl'] ?? res['url'] ?? res['video_playback_url'];
        if (url != null && url.toString().isNotEmpty) {
          cctvPlaybackUrl.value = url.toString();
        } else {
          cctvPlaybackUrl.value = null;
        }
      }
    } catch (e) {
      AppLogger.warning('Error fetching match CCTV recording: $e');
    } finally {
      isLoadingVideos.value = false;
    }
  }

  Future<bool> rescheduleMatch({
    required String gameId,
    required String matchDate,
    required String startTime,
    required String endTime,
    String? courtId,
    String? reason,
  }) async {
    isLoading.value = true;
    try {
      final updated = await repository.rescheduleGame(
        gameId,
        matchDate: matchDate,
        startTime: startTime,
        endTime: endTime,
        courtId: courtId,
        reason: reason,
      );
      selectedGame.value = updated;
      await fetchClubGames();
      ErrorHandler.showSuccessSnackBar(
        'Match Rescheduled!',
        'The match has been rescheduled to $matchDate ($startTime - $endTime). Players have been notified.',
      );
      return true;
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Reschedule Error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void selectCamera(VideoModel video) {
    selectedVideo.value = video;
    if (video.playbackUrl.isNotEmpty) {
      cctvPlaybackUrl.value = video.playbackUrl;
    }
  }

  Future<void> approvePlayerGame(String gameId) async {
    isLoading.value = true;
    try {
      await repository.approvePlayerGame(gameId);
      await fetchClubGames();
      if (selectedGame.value != null && selectedGame.value!.id == gameId) {
        final updated = await repository.getClubGames();
        selectedGame.value = updated.firstWhereOrNull((g) => g.id == gameId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Match Approved!', 'Match has been approved and scheduled on court.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Approval Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPlayerGame(String gameId, String reason) async {
    isLoading.value = true;
    try {
      await repository.rejectPlayerGame(gameId, reason);
      await fetchClubGames();
      if (selectedGame.value != null && selectedGame.value!.id == gameId) {
        final updated = await repository.getClubGames();
        selectedGame.value = updated.firstWhereOrNull((g) => g.id == gameId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Match Rejected', 'Match rejected and entry fees refunded.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Rejection Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelMatchWithRefunds(String gameId, String reason) async {
    isLoading.value = true;
    try {
      await repository.cancelGameWithRefunds(gameId, reason);
      await fetchClubGames();
      if (selectedGame.value != null && selectedGame.value!.id == gameId) {
        final updated = await repository.getClubGames();
        selectedGame.value = updated.firstWhereOrNull((g) => g.id == gameId);
      }
      ErrorHandler.showSuccessSnackBar('Match Cancelled',
          'Match cancelled and refunds processed to player wallets.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Cancellation Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startGame(String gameId) async {
    isLoading.value = true;
    try {
      final updated = await repository.startGame(gameId);
      selectedGame.value = updated;
      fetchClubGames();
      ErrorHandler.showSuccessSnackBar('Match Started',
          'Match is now ONGOING. CCTV recording auto-started!');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Start Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitMatchScore(String gameId, int scoreA, int scoreB,
      {bool isFinal = true}) async {
    isLoading.value = true;
    try {
      await repository.submitMatchScore(gameId, scoreA, scoreB,
          isFinal: isFinal);
      await fetchClubGames();
      if (selectedGame.value != null && selectedGame.value!.id == gameId) {
        final current = selectedGame.value!;
        selectedGame.value = GameModel(
          id: current.id,
          title: current.title,
          clubId: current.clubId,
          clubName: current.clubName,
          courtId: current.courtId,
          courtName: current.courtName,
          matchDate: current.matchDate,
          startTime: current.startTime,
          endTime: current.endTime,
          status: current.status,
          format: current.format,
          perPlayerFee: current.perPlayerFee,
          maxPlayers: current.maxPlayers,
          currentPlayers: current.currentPlayers,
          skillRequirement: current.skillRequirement,
          privacy: current.privacy,
          creatorId: current.creatorId,
          creatorRoleName: current.creatorRoleName,
          createdByPlayer: current.createdByPlayer,
          teamAScore: scoreA,
          teamBScore: scoreB,
          winnerTeam: current.winnerTeam,
          userTeam: current.userTeam,
          userPosition: current.userPosition,
          description: current.description,
          waitlistPosition: current.waitlistPosition,
          roster: current.roster,
          videoPlaybackUrl: current.videoPlaybackUrl,
        );
      }
      ErrorHandler.showSuccessSnackBar(
          'Score Saved', 'Final match score updated to $scoreA - $scoreB');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Score Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeGame(
      String gameId, int teamAScore, int teamBScore) async {
    isLoading.value = true;
    try {
      final updated =
          await repository.completeGame(gameId, teamAScore, teamBScore);
      selectedGame.value = updated;
      fetchClubGames();
      await fetchMatchRecording(gameId);
      ErrorHandler.showSuccessSnackBar(
          'Match Completed', 'Match is finished and moved to Match History.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Complete Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePauseGame(String gameId) {
    if (selectedGame.value == null) return;
    final current = selectedGame.value!;
    final isCurrentlyPaused = current.status.toUpperCase() == 'PAUSED';
    final newStatus = isCurrentlyPaused ? 'ONGOING' : 'PAUSED';

    selectedGame.value = GameModel(
      id: current.id,
      title: current.title,
      clubId: current.clubId,
      clubName: current.clubName,
      courtId: current.courtId,
      courtName: current.courtName,
      matchDate: current.matchDate,
      startTime: current.startTime,
      endTime: current.endTime,
      status: newStatus,
      format: current.format,
      perPlayerFee: current.perPlayerFee,
      maxPlayers: current.maxPlayers,
      currentPlayers: current.currentPlayers,
      skillRequirement: current.skillRequirement,
      privacy: current.privacy,
      creatorId: current.creatorId,
      creatorRoleName: current.creatorRoleName,
      createdByPlayer: current.createdByPlayer,
      teamAScore: current.teamAScore,
      teamBScore: current.teamBScore,
      winnerTeam: current.winnerTeam,
      userTeam: current.userTeam,
      userPosition: current.userPosition,
      description: current.description,
      waitlistPosition: current.waitlistPosition,
      roster: current.roster,
      videoPlaybackUrl: current.videoPlaybackUrl,
    );

    ErrorHandler.showSuccessSnackBar(
      isCurrentlyPaused ? 'Match Resumed' : 'Match Paused',
      isCurrentlyPaused ? 'Match gameplay active.' : 'Match gameplay paused.',
    );
  }
}
