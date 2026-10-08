import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/manager_repository.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/game_model.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';

class ManagerDashboardController extends GetxController with WidgetsBindingObserver {
  final ManagerRepository repository = Get.find<ManagerRepository>();

  final Rxn<ManagerDashboardModel> dashboard = Rxn<ManagerDashboardModel>();
  final RxList<CourtModel> courts = <CourtModel>[].obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<SlotRequestModel> pendingRequests = <SlotRequestModel>[].obs;
  final RxList<GameModel> clubMatches = <GameModel>[].obs;

  final RxList<GameModel> pendingPlayerGames = <GameModel>[].obs;
  final RxList<Map<String, dynamic>> court1Slots = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> court2Slots = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> currentCourtSlots = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> playersList = <Map<String, dynamic>>[].obs;

  final RxInt selectedCourtIndex = 0.obs;
  final RxString selectedMatchTab = 'TODAY'.obs; // TODAY, UPCOMING, ONGOING, CANCELLED
  final RxBool isLoading = false.obs;
  final RxBool isSlotsLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxInt selectedNavIndex = 0.obs;

  final matchTabs = ['TODAY', 'UPCOMING', 'ONGOING', 'CANCELLED'];

  List<GameModel> get court1Games {
    final all = <GameModel>[...pendingPlayerGames, ...clubMatches];
    final seen = <String>{};
    return all.where((g) {
      if (seen.contains(g.id)) return false;
      seen.add(g.id);
      return g.courtId == 'court_1' || g.courtName == 'Court 1';
    }).toList();
  }

  List<GameModel> get court2Games {
    final all = <GameModel>[...pendingPlayerGames, ...clubMatches];
    final seen = <String>{};
    return all.where((g) {
      if (seen.contains(g.id)) return false;
      seen.add(g.id);
      return g.courtId == 'court_2' || g.courtName == 'Court 2';
    }).toList();
  }

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadManagerData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.info('⚡ App resumed: Refreshing manager dashboard data');
      loadManagerData();
    }
  }

  Future<void> loadManagerData() async {
    isLoading.value = true;
    try {
      final d = await repository.getDashboard();
      dashboard.value = d;

      final reqs = await repository.getPendingRequests();
      pendingRequests.assignAll(reqs);

      final matches =
          await repository.getClubMatches(tab: selectedMatchTab.value);
      clubMatches.assignAll(matches);

      List<CourtModel> crts = [];
      try {
        crts = await repository.getClubCourts();
      } catch (e) {
        AppLogger.warning('Error fetching club courts: $e');
      }

      if (crts.isNotEmpty) {
        courts.assignAll(crts);
      } else {
        const clubId = 'all_stars_arena_club';
        const clubName = 'All Stars Turf Raipur';
        courts.assignAll([
          CourtModel(
            id: 'court_1',
            clubId: clubId,
            clubName: clubName,
            name: 'Court 1',
            surfaceType: '3G Turf',
            basePricePerHour: 1200.0,
            status: 'AVAILABLE',
            city: 'Raipur',
            address: 'Raipur',
          ),
          CourtModel(
            id: 'court_2',
            clubId: clubId,
            clubName: clubName,
            name: 'Court 2',
            surfaceType: '3G Turf',
            basePricePerHour: 1200.0,
            status: 'AVAILABLE',
            city: 'Raipur',
            address: 'Raipur',
          ),
        ]);
      }

      final bkgs = await repository.getClubBookings();
      bookings.assignAll(bkgs);

      await fetchPendingPlayerGames();

      if (courts.isNotEmpty) {
        final clampedIndex = selectedCourtIndex.value.clamp(0, courts.length - 1);
        final courtId = courts[clampedIndex].id;
        await fetchCourtSlots(courtId, courtIndex: clampedIndex + 1);
      }
    } catch (e) {
      AppLogger.warning('Manager dashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClubMatches(String tab) async {
    selectedMatchTab.value = tab;
    try {
      final list = await repository.getClubMatches(tab: tab);
      clubMatches.assignAll(list);
    } catch (e) {
      clubMatches.clear();
      ErrorHandler.showErrorSnackBar('Error', e);
    }
  }

  Future<void> selectCourt(int index) async {
    if (courts.isEmpty) return;
    final clamped = index.clamp(0, courts.length - 1);
    selectedCourtIndex.value = clamped;
    final courtId = courts[clamped].id;
    await fetchCourtSlots(courtId, courtIndex: clamped + 1);
  }

  Future<void> fetchCourtSlots(String courtId, {int courtIndex = 1, String? date}) async {
    isSlotsLoading.value = true;
    try {
      final slots = await repository.getCourtSlots(courtId, date: date);
      currentCourtSlots.assignAll(slots);
      if (courtIndex == 1) {
        court1Slots.assignAll(slots);
      } else {
        court2Slots.assignAll(slots);
      }
    } catch (e) {
      AppLogger.warning('Error fetching slots for court $courtId: $e');
      currentCourtSlots.clear();
      if (courtIndex == 1) {
        court1Slots.clear();
      } else {
        court2Slots.clear();
      }
    } finally {
      isSlotsLoading.value = false;
    }
  }

  Future<void> approveSlotRequest(String requestId) async {
    isActionLoading.value = true;
    try {
      await repository.approveSlotRequest(requestId);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar(
        'Request Approved!',
        'Player has been assigned to active match roster',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Approval Failed', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> rejectSlotRequest(String requestId, String reason) async {
    isActionLoading.value = true;
    try {
      await repository.rejectSlotRequest(requestId, reason);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar(
        'Request Rejected',
        'Player notified and entry fee refunded',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Rejection Failed', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> cancelMatchWithRefunds(String gameId, String reason) async {
    isActionLoading.value = true;
    try {
      await repository.cancelGameWithRefunds(gameId, reason);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar(
        'Match Cancelled',
        'Match cancelled and full atomic refunds processed to player wallets.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Cancellation Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> fetchPendingPlayerGames() async {
    try {
      final list = await repository.getPendingPlayerGames();
      pendingPlayerGames.assignAll(list);
    } catch (e) {
      AppLogger.warning('Error fetching pending player games: $e');
    }
  }

  Future<void> approvePlayerGame(String gameId) async {
    isActionLoading.value = true;
    try {
      await repository.approvePlayerGame(gameId);
      await loadManagerData();
      await fetchPendingPlayerGames();
      ErrorHandler.showSuccessSnackBar(
        'Match Approved!',
        'Player-created match has been accepted and scheduled on the court',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Approval Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> rejectPlayerGame(String gameId, String reason) async {
    isActionLoading.value = true;
    try {
      await repository.rejectPlayerGame(gameId, reason);
      await loadManagerData();
      await fetchPendingPlayerGames();
      ErrorHandler.showSuccessSnackBar(
        'Match Rejected',
        'Match rejected and paid players refunded to their wallets',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Rejection Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> gameData) async {
    isActionLoading.value = true;
    try {
      await repository.updateGame(gameId, gameData);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar(
        'Match Updated',
        'Match details updated successfully',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Update Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> fetchAllPlayers({String? search, String? status}) async {
    try {
      final list = await repository.getAllPlayers(search: search, status: status);
      playersList.assignAll(list);
    } catch (e) {
      AppLogger.warning('Error fetching players: $e');
    }
  }

  Future<void> blockPlayer(String playerId, String reason) async {
    isActionLoading.value = true;
    try {
      await repository.blockPlayer(playerId, reason);
      await fetchAllPlayers();
      ErrorHandler.showSuccessSnackBar('Player Blocked', 'Player access has been restricted');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Block Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> unblockPlayer(String playerId) async {
    isActionLoading.value = true;
    try {
      await repository.unblockPlayer(playerId);
      await fetchAllPlayers();
      ErrorHandler.showSuccessSnackBar('Player Unblocked', 'Player access restored');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Unblock Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> submitMatchScore(String gameId, int teamAScore, int teamBScore, {bool isFinal = true}) async {
    isActionLoading.value = true;
    try {
      await repository.submitMatchScore(gameId, teamAScore, teamBScore, isFinal: isFinal);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar('Score Recorded', 'Official match result has been published');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Score Submission Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> stopMatchRecording(String gameId) async {
    isActionLoading.value = true;
    try {
      await repository.stopMatchRecording(gameId);
      ErrorHandler.showSuccessSnackBar('Recording Stopped', 'CCTV recording stopped and stored to AWS S3');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Stop Recording Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }
}
