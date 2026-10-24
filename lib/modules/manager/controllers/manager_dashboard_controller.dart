import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:all_stars_arena/modules/manager/repositories/manager_repository.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/game_model.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';

class ManagerDashboardController extends GetxController
    with WidgetsBindingObserver {
  final ManagerRepository repository = Get.find<ManagerRepository>();

  final Rxn<ManagerDashboardModel> dashboard = Rxn<ManagerDashboardModel>();
  final RxMap<String, dynamic> clubMetrics = <String, dynamic>{}.obs;
  final RxList<CourtModel> courts = <CourtModel>[].obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<SlotRequestModel> pendingRequests = <SlotRequestModel>[].obs;
  final RxList<GameModel> clubMatches = <GameModel>[].obs;

  final RxList<GameModel> pendingPlayerGames = <GameModel>[].obs;
  final RxList<Map<String, dynamic>> court1Slots = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> court2Slots = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> currentCourtSlots =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> playersList = <Map<String, dynamic>>[].obs;

  final RxInt selectedCourtIndex = 0.obs;
  final RxString selectedMatchTab = 'TODAY'.obs;
  final RxString selectedDateFilter = 'ALL'.obs;
  final Rxn<DateTime> customSelectedDate = Rxn<DateTime>();
  final RxBool isLoading = false.obs;
  final RxBool isSlotsLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxBool isUpdatingCourt = false.obs;
  final RxInt selectedNavIndex = 0.obs;
  final RxString searchQuery = ''.obs;

  List<Map<String, dynamic>> get filteredCourtSlots {
    List<Map<String, dynamic>> list = List.from(currentCourtSlots);

    list = list.where((slot) {
      final status = (slot['status'] ?? '').toString().toUpperCase();
      final approvalStatus =
          (slot['approvalStatus'] ?? slot['approval_status'] ?? '')
              .toString()
              .toUpperCase();
      return status != 'COMPLETED' &&
          status != 'CANCELLED' &&
          approvalStatus != 'REJECTED';
    }).toList();

    // Deduplicate court slots by unique game / slot ID
    final seen = <String>{};
    final deduplicated = <Map<String, dynamic>>[];
    for (final slot in list) {
      final id = (slot['gameId'] ?? slot['id'] ?? slot['_id'] ?? '').toString();
      final key = id.isNotEmpty
          ? id
          : '${slot['title']}_${slot['startTime']}_${slot['start_time']}';
      if (seen.contains(key)) continue;
      seen.add(key);
      deduplicated.add(slot);
    }
    list = deduplicated;

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      list = list.where((slot) {
        final title =
            (slot['title'] ?? slot['gameTitle'] ?? '').toString().toLowerCase();
        final host = (slot['hostName'] ?? slot['host_name'] ?? '')
            .toString()
            .toLowerCase();
        final status = (slot['status'] ?? slot['approvalStatus'] ?? '')
            .toString()
            .toLowerCase();
        final format = (slot['format'] ?? '').toString().toLowerCase();
        return title.contains(q) ||
            host.contains(q) ||
            status.contains(q) ||
            format.contains(q);
      }).toList();
    }
    return list;
  }

  final matchTabs = ['TODAY', 'UPCOMING', 'ONGOING', 'CANCELLED'];

  String? get formattedQueryDate {
    if (selectedDateFilter.value == 'ALL') return null;
    if (selectedDateFilter.value == 'TODAY') {
      return DateTime.now().toIso8601String().split('T')[0];
    }
    if (selectedDateFilter.value == 'TOMORROW') {
      return DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];
    }
    return selectedDateFilter.value;
  }

  Future<void> changeDateFilter(String filter) async {
    if (filter == 'CUSTOM') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final initial = (customSelectedDate.value != null &&
              !customSelectedDate.value!.isBefore(today))
          ? customSelectedDate.value!
          : today;

      final picked = await showDatePicker(
        context: Get.context!,
        initialDate: initial,
        firstDate: today,
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        customSelectedDate.value = picked;
        selectedDateFilter.value = picked.toIso8601String().split('T')[0];
        if (courts.isNotEmpty) {
          final clamped = selectedCourtIndex.value.clamp(0, courts.length - 1);
          await fetchCourtSlots(courts[clamped].id,
              courtIndex: clamped + 1, date: formattedQueryDate);
        }
      }
      return;
    }

    selectedDateFilter.value = filter;
    if (courts.isNotEmpty) {
      final clamped = selectedCourtIndex.value.clamp(0, courts.length - 1);
      await fetchCourtSlots(courts[clamped].id,
          courtIndex: clamped + 1, date: formattedQueryDate);
    }
  }

  Future<void> selectCourt(int index) async {
    if (courts.isEmpty) return;
    final clamped = index.clamp(0, courts.length - 1);
    selectedCourtIndex.value = clamped;
    final courtId = courts[clamped].id;
    await fetchCourtSlots(courtId,
        courtIndex: clamped + 1, date: formattedQueryDate);
  }

  List<GameModel> get court1Games {
    final all = <GameModel>[...pendingPlayerGames, ...clubMatches];
    final seen = <String>{};
    return all.where((g) {
      if (seen.contains(g.id)) return false;
      seen.add(g.id);
      return g.courtId == 'court_1';
    }).toList();
  }

  List<GameModel> get court2Games {
    final all = <GameModel>[...pendingPlayerGames, ...clubMatches];
    final seen = <String>{};
    return all.where((g) {
      if (seen.contains(g.id)) return false;
      seen.add(g.id);
      return g.courtId == 'court_2';
    }).toList();
  }

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
    if (index == 1) {
      loadManagerData();
    }
  }

  Future<bool> updateCourtStatusAndPrice({
    required String courtId,
    required double basePrice,
    required String status,
  }) async {
    isUpdatingCourt.value = true;
    try {
      final updated = await repository.updateCourtPricing(
        courtId: courtId,
        basePrice: basePrice,
        status: status,
      );
      final idx = courts.indexWhere((c) => c.id == courtId);
      if (idx != -1) {
        courts[idx] = updated;
      }
      Get.snackbar(
        'Court Updated',
        '${updated.name} updated: ₹${basePrice.toStringAsFixed(0)}/hr • $status',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF00C853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      isUpdatingCourt.value = false;
      return true;
    } catch (e) {
      isUpdatingCourt.value = false;
      ErrorHandler.showErrorSnackBar('Court Update Failed', e);
      return false;
    }
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

      courts.assignAll(crts);
      AppLogger.info(
          '[ManagerCourt] loaded courts count: ${courts.length}, IDs: ${courts.map((c) => c.id).toList()}');

      final bkgs = await repository.getClubBookings();
      bookings.assignAll(bkgs);

      await fetchPendingPlayerGames();
      await fetchClubMetrics();

      if (courts.isNotEmpty) {
        final clampedIndex =
            selectedCourtIndex.value.clamp(0, courts.length - 1);
        final courtId = courts[clampedIndex].id;
        await fetchCourtSlots(courtId,
            courtIndex: clampedIndex + 1, date: formattedQueryDate);
      }
    } catch (e) {
      AppLogger.warning('Manager dashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClubMetrics() async {
    try {
      final metrics = await repository.getClubMetrics();
      clubMetrics.assignAll(metrics);
    } catch (e) {
      AppLogger.warning('Error fetching club metrics: $e');
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

  Future<void> fetchCourtSlots(String courtId,
      {int courtIndex = 1, String? date}) async {
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

  final RxBool isPlayersLoading = false.obs;
  final Rxn<Map<String, dynamic>> selectedPlayerDetail =
      Rxn<Map<String, dynamic>>();

  Future<void> fetchAllPlayers({String? search, String? status}) async {
    isPlayersLoading.value = true;
    try {
      final list =
          await repository.getAllPlayers(search: search, status: status);

      list.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      playersList.assignAll(list);
    } catch (e) {
      AppLogger.warning('Error fetching players: $e');
    } finally {
      isPlayersLoading.value = false;
    }
  }

  Future<void> fetchPlayerDetailHistory(String playerId,
      {bool forceReload = false}) async {
    isActionLoading.value = true;
    try {
      if (forceReload) {
        selectedPlayerDetail.value = null;
      }
      final data = await repository.getPlayerDetailHistory(playerId);
      selectedPlayerDetail.value = data;
    } catch (e) {
      AppLogger.warning('Error fetching player detail history: $e');
      ErrorHandler.showErrorSnackBar('Player Details Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> blockPlayer(String playerId, String reason) async {
    isActionLoading.value = true;
    try {
      await repository.blockPlayer(playerId, reason);
      await fetchAllPlayers();
      if (selectedPlayerDetail.value != null) {
        await fetchPlayerDetailHistory(playerId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Player Blocked', 'Player access has been restricted');
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
      if (selectedPlayerDetail.value != null) {
        await fetchPlayerDetailHistory(playerId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Player Unblocked', 'Player access restored');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Unblock Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> submitMatchScore(String gameId, int teamAScore, int teamBScore,
      {bool isFinal = true}) async {
    isActionLoading.value = true;
    try {
      await repository.submitMatchScore(gameId, teamAScore, teamBScore,
          isFinal: isFinal);
      await loadManagerData();
      ErrorHandler.showSuccessSnackBar(
          'Score Recorded', 'Official match result has been published');
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
      ErrorHandler.showSuccessSnackBar(
          'Recording Stopped', 'CCTV recording stopped and stored to AWS S3');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Stop Recording Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }
}
