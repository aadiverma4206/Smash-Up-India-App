import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smash_up_india/modules/manager/repositories/manager_repository.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/game_model.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/match_date_picker_dialog.dart';

class ManagerDashboardController extends GetxController
    with WidgetsBindingObserver {
  final ManagerRepository repository = Get.find<ManagerRepository>();

  final Rxn<ManagerDashboardModel> dashboard = Rxn<ManagerDashboardModel>();
  final RxMap<String, dynamic> clubMetrics = <String, dynamic>{}.obs;
  final RxList<CourtModel> courts = <CourtModel>[].obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<SlotRequestModel> pendingRequests = <SlotRequestModel>[].obs;
  final RxList<GameModel> clubMatches = <GameModel>[].obs;
  final RxList<GameModel> allClubGames = <GameModel>[].obs;

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

  Set<String> get scheduledMatchDates {
    final dates = <String>{};

    void addDateStr(dynamic raw) {
      if (raw == null) return;
      final dt = AppDateUtils.parseDate(raw);
      if (dt != null) {
        final formatted =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        dates.add(formatted);
      }
    }

    if (courts.isEmpty) {
      // Fallback if courts list is not yet populated
      for (final game in allClubGames) {
        addDateStr(game.matchDate);
      }
      for (final game in clubMatches) {
        addDateStr(game.matchDate);
      }
      for (final slot in currentCourtSlots) {
        addDateStr(slot['matchDate'] ??
            slot['match_date'] ??
            slot['bookingDate'] ??
            slot['booking_date']);
      }
      return dates;
    }

    final clampedIndex = selectedCourtIndex.value.clamp(0, courts.length - 1);
    final targetCourt = courts[clampedIndex];
    final targetIndex = clampedIndex;
    final targetNum =
        (targetIndex + 1).toString(); // "1" for Court 1, "2" for Court 2

    bool isForCurrentCourt(String? cId, String? cName) {
      final targetId = targetCourt.id.toLowerCase().trim();
      final targetName = targetCourt.name.toLowerCase().trim();

      final id = (cId ?? '').toLowerCase().trim();
      final name = (cName ?? '').toLowerCase().trim();

      if (id.isNotEmpty) {
        if (id == targetId ||
            id == 'court_$targetNum' ||
            id == targetNum ||
            id.contains('court_$targetNum')) {
          return true;
        }
      }
      if (name.isNotEmpty) {
        if (name == targetName) return true;
        if (name.contains('court $targetNum')) return true;
        if (name.contains('court_$targetNum')) return true;
        if (name.contains(targetNum)) return true;
      }
      return false;
    }

    // 1. All club games filtered by active court
    for (final game in allClubGames) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addDateStr(game.matchDate);
      }
    }

    // 2. Club matches filtered by active court
    for (final game in clubMatches) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addDateStr(game.matchDate);
      }
    }

    // 3. Pending player games filtered by active court
    for (final game in pendingPlayerGames) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addDateStr(game.matchDate);
      }
    }

    // 4. Current court slots (already fetched specifically for active court)
    for (final slot in currentCourtSlots) {
      addDateStr(slot['matchDate'] ??
          slot['match_date'] ??
          slot['bookingDate'] ??
          slot['booking_date']);
    }

    if (targetIndex == 0) {
      for (final slot in court1Slots) {
        addDateStr(slot['matchDate'] ??
            slot['match_date'] ??
            slot['bookingDate'] ??
            slot['booking_date']);
      }
    } else if (targetIndex == 1) {
      for (final slot in court2Slots) {
        addDateStr(slot['matchDate'] ??
            slot['match_date'] ??
            slot['bookingDate'] ??
            slot['booking_date']);
      }
    }

    // 5. Bookings filtered by active court
    for (final b in bookings) {
      if (isForCurrentCourt(b.courtId, b.courtName)) {
        addDateStr(b.bookingDate);
      }
    }

    return dates;
  }

  Set<String> get upcomingMatchDates {
    final dates = <String>{};

    void addUpcomingDateStr(dynamic rawDate, dynamic startTime) {
      if (rawDate == null) return;
      if (AppDateUtils.isMatchInFuture(rawDate, startTime)) {
        final dt = AppDateUtils.parseDate(rawDate);
        if (dt != null) {
          final formatted =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          dates.add(formatted);
        }
      }
    }

    if (courts.isEmpty) {
      for (final game in allClubGames) {
        addUpcomingDateStr(game.matchDate, game.startTime);
      }
      for (final game in clubMatches) {
        addUpcomingDateStr(game.matchDate, game.startTime);
      }
      for (final slot in currentCourtSlots) {
        addUpcomingDateStr(
          slot['matchDate'] ??
              slot['match_date'] ??
              slot['bookingDate'] ??
              slot['booking_date'],
          slot['startTime'] ?? slot['start_time'],
        );
      }
      return dates;
    }

    final clampedIndex = selectedCourtIndex.value.clamp(0, courts.length - 1);
    final targetCourt = courts[clampedIndex];
    final targetIndex = clampedIndex;
    final targetNum = (targetIndex + 1).toString();

    bool isForCurrentCourt(String? cId, String? cName) {
      final targetId = targetCourt.id.toLowerCase().trim();
      final targetName = targetCourt.name.toLowerCase().trim();

      final id = (cId ?? '').toLowerCase().trim();
      final name = (cName ?? '').toLowerCase().trim();

      if (id.isNotEmpty) {
        if (id == targetId ||
            id == 'court_$targetNum' ||
            id == targetNum ||
            id.contains('court_$targetNum')) {
          return true;
        }
      }
      if (name.isNotEmpty) {
        if (name == targetName) return true;
        if (name.contains('court $targetNum')) return true;
        if (name.contains('court_$targetNum')) return true;
        if (name.contains(targetNum)) return true;
      }
      return false;
    }

    for (final game in allClubGames) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addUpcomingDateStr(game.matchDate, game.startTime);
      }
    }

    for (final game in clubMatches) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addUpcomingDateStr(game.matchDate, game.startTime);
      }
    }

    for (final game in pendingPlayerGames) {
      if (isForCurrentCourt(game.courtId, game.courtName)) {
        addUpcomingDateStr(game.matchDate, game.startTime);
      }
    }

    for (final slot in currentCourtSlots) {
      addUpcomingDateStr(
        slot['matchDate'] ??
            slot['match_date'] ??
            slot['bookingDate'] ??
            slot['booking_date'],
        slot['startTime'] ?? slot['start_time'],
      );
    }

    if (targetIndex == 0) {
      for (final slot in court1Slots) {
        addUpcomingDateStr(
          slot['matchDate'] ??
              slot['match_date'] ??
              slot['bookingDate'] ??
              slot['booking_date'],
          slot['startTime'] ?? slot['start_time'],
        );
      }
    } else if (targetIndex == 1) {
      for (final slot in court2Slots) {
        addUpcomingDateStr(
          slot['matchDate'] ??
              slot['match_date'] ??
              slot['bookingDate'] ??
              slot['booking_date'],
          slot['startTime'] ?? slot['start_time'],
        );
      }
    }

    for (final b in bookings) {
      if (isForCurrentCourt(b.courtId, b.courtName)) {
        addUpcomingDateStr(b.bookingDate, b.startTime);
      }
    }

    return dates;
  }

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

      final picked = await showMatchDatePicker(
        context: Get.context!,
        initialDate: initial,
        firstDate: today,
        lastDate: DateTime(2030),
        matchDates: scheduledMatchDates,
        upcomingMatchDates: upcomingMatchDates,
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

  List<GameModel> _gamesForCourt(int courtNum) {
    final all = <GameModel>[...pendingPlayerGames, ...clubMatches];
    final seen = <String>{};
    return all.where((g) {
      if (seen.contains(g.id)) return false;
      seen.add(g.id);
      return _isGameForCourt(g, courtNum);
    }).toList();
  }

  List<GameModel> get court1Games => _gamesForCourt(1);
  List<GameModel> get court2Games => _gamesForCourt(2);
  List<GameModel> get court3Games => _gamesForCourt(3);
  List<GameModel> get padelCourtGames => _gamesForCourt(4);

  bool _isGameForCourt(GameModel game, int courtNum) {
    final cId = (game.courtId ?? '').toLowerCase().trim();
    final cName = game.courtName.toLowerCase().trim();
    final isPadel = cId.contains('padel') || cName.contains('padel');

    if (courtNum == 4) {
      return isPadel;
    }
    if (isPadel) {
      return false;
    }

    final targetStr = 'court_$courtNum';
    final targetName = 'court $courtNum';

    if (cId == targetStr ||
        cId == courtNum.toString() ||
        cId.endsWith(courtNum.toString())) {
      return true;
    }
    if (cName.contains(targetName) || cName.contains(targetStr)) {
      return true;
    }
    if (courtNum == 1 &&
        (cName.contains('pitch 1') || cId.contains('court_1'))) {
      return true;
    }
    if (courtNum == 2 &&
        (cName.contains('pitch 2') || cId.contains('court_2'))) {
      return true;
    }
    if (courtNum == 3 &&
        (cName.contains('pitch 3') || cId.contains('court_3'))) {
      return true;
    }
    return false;
  }

  GameModel? getCourtFeaturedMatch(int courtNum) {
    if (courtNum == 1 && dashboard.value?.court1Match != null) {
      return dashboard.value!.court1Match;
    }
    if (courtNum == 2 && dashboard.value?.court2Match != null) {
      return dashboard.value!.court2Match;
    }

    final Map<String, GameModel> allGamesMap = {};
    for (final g in allClubGames) {
      allGamesMap[g.id] = g;
    }
    for (final g in clubMatches) {
      allGamesMap[g.id] = g;
    }
    for (final g in pendingPlayerGames) {
      allGamesMap[g.id] = g;
    }

    final courtGames =
        allGamesMap.values.where((g) => _isGameForCourt(g, courtNum)).toList();

    if (courtGames.isEmpty) return null;

    final ongoing = courtGames.where((g) {
      final st = g.status.toUpperCase();
      return st == 'ONGOING' || st == 'STARTED';
    }).toList();

    if (ongoing.isNotEmpty) {
      return ongoing.first;
    }

    final upcoming = courtGames.where((g) {
      final st = g.status.toUpperCase();
      return st != 'CANCELLED' && st != 'COMPLETED' && st != 'FINISHED';
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final dateCmp = a.matchDate.compareTo(b.matchDate);
      if (dateCmp != 0) return dateCmp;
      return a.startTime.compareTo(b.startTime);
    });

    return upcoming.first;
  }

  GameModel? get court1FeaturedMatch => getCourtFeaturedMatch(1);
  GameModel? get court2FeaturedMatch => getCourtFeaturedMatch(2);
  GameModel? get court3FeaturedMatch => getCourtFeaturedMatch(3);
  GameModel? get padelCourtFeaturedMatch => getCourtFeaturedMatch(4);

  int get futureBookingsCount {
    if (clubMetrics['futureBookings'] != null) {
      return (clubMetrics['futureBookings'] as num).toInt();
    }
    if (dashboard.value != null && dashboard.value!.futureBookings > 0) {
      return dashboard.value!.futureBookings;
    }

    final Set<String> uniqueFutureIds = {};

    for (final b in bookings) {
      final st = b.status.toUpperCase();
      if (st != 'CANCELLED' && st != 'REJECTED') {
        if (AppDateUtils.isMatchInFuture(b.bookingDate, b.startTime) ||
            AppDateUtils.isMatchInFuture(b.bookingDate, b.endTime)) {
          uniqueFutureIds.add('b_${b.id}');
        }
      }
    }

    for (final g in allClubGames) {
      final st = g.status.toUpperCase();
      if (st != 'CANCELLED' &&
          st != 'COMPLETED' &&
          st != 'FINISHED' &&
          st != 'REJECTED') {
        if (AppDateUtils.isMatchInFuture(g.matchDate, g.startTime) ||
            AppDateUtils.isMatchInFuture(g.matchDate, g.endTime)) {
          uniqueFutureIds.add('g_${g.id}');
        }
      }
    }

    for (final g in clubMatches) {
      final st = g.status.toUpperCase();
      if (st != 'CANCELLED' &&
          st != 'COMPLETED' &&
          st != 'FINISHED' &&
          st != 'REJECTED') {
        if (AppDateUtils.isMatchInFuture(g.matchDate, g.startTime) ||
            AppDateUtils.isMatchInFuture(g.matchDate, g.endTime)) {
          uniqueFutureIds.add('g_${g.id}');
        }
      }
    }

    return uniqueFutureIds.length;
  }

  int get totalBookingsCount {
    if (clubMetrics['bookings'] != null &&
        (clubMetrics['bookings'] as num) > 0) {
      return (clubMetrics['bookings'] as num).toInt();
    }
    if (clubMetrics['totalBookings'] != null &&
        (clubMetrics['totalBookings'] as num) > 0) {
      return (clubMetrics['totalBookings'] as num).toInt();
    }
    if (dashboard.value != null && dashboard.value!.totalBookings > 0) {
      return dashboard.value!.totalBookings;
    }

    final Set<String> uniqueIds = {};

    for (final b in bookings) {
      final st = b.status.toUpperCase();
      if (st != 'CANCELLED' && st != 'REJECTED') {
        uniqueIds.add('b_${b.id}');
      }
    }

    for (final g in allClubGames) {
      final st = g.status.toUpperCase();
      if (st != 'CANCELLED' && st != 'REJECTED') {
        uniqueIds.add('g_${g.id}');
      }
    }

    for (final g in clubMatches) {
      final st = g.status.toUpperCase();
      if (st != 'CANCELLED' && st != 'REJECTED') {
        uniqueIds.add('g_${g.id}');
      }
    }

    return uniqueIds.length;
  }

  int get completedMatchesCount {
    if (clubMetrics['completedMatches'] != null &&
        (clubMetrics['completedMatches'] as num) > 0) {
      return (clubMetrics['completedMatches'] as num).toInt();
    }
    if (dashboard.value != null && dashboard.value!.completedMatches > 0) {
      return dashboard.value!.completedMatches;
    }

    final Set<String> uniqueCompletedIds = {};

    for (final g in allClubGames) {
      final st = g.status.toUpperCase();
      if (st == 'COMPLETED' || st == 'FINISHED') {
        uniqueCompletedIds.add(g.id);
      } else if (st != 'CANCELLED' && g.matchDate.isNotEmpty) {
        if (AppDateUtils.isMatchInPast(g.matchDate, g.endTime)) {
          uniqueCompletedIds.add(g.id);
        }
      }
    }

    for (final g in clubMatches) {
      final st = g.status.toUpperCase();
      if (st == 'COMPLETED' || st == 'FINISHED') {
        uniqueCompletedIds.add(g.id);
      } else if (st != 'CANCELLED' && g.matchDate.isNotEmpty) {
        if (AppDateUtils.isMatchInPast(g.matchDate, g.endTime)) {
          uniqueCompletedIds.add(g.id);
        }
      }
    }

    return uniqueCompletedIds.length;
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
      ErrorHandler.showSuccessSnackBar(
        'Court Updated',
        '${updated.name} updated: ₹${basePrice.toStringAsFixed(0)}/hr • $status',
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

    if (Get.isRegistered<ConnectivityService>()) {
      ConnectivityService.to.isConnected.listen((connected) {
        if (connected) {
          AppLogger.info(
              '⚡ Connection restored: Auto-refreshing manager dashboard');
          loadManagerData();
        }
      });
    }
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

      try {
        final allGames = await repository.getClubGames();
        allClubGames.assignAll(allGames);
      } catch (e) {
        AppLogger.warning('Error fetching all club games: $e');
      }

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

  String? lastPlayersSearch;
  String? lastPlayersStatus;

  Future<void> fetchAllPlayers({String? search, String? status}) async {
    lastPlayersSearch = search;
    lastPlayersStatus = status;

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

    // Instant local update so player updates/removes immediately in UI
    final index = playersList.indexWhere(
        (p) => (p['id'] ?? p['userId'] ?? '').toString() == playerId);
    if (index != -1) {
      final updatedPlayer = Map<String, dynamic>.from(playersList[index]);
      updatedPlayer['status'] = 'SUSPENDED';
      updatedPlayer['isBlocked'] = true;
      playersList[index] = updatedPlayer;
      playersList.refresh();
    }

    try {
      await repository.blockPlayer(playerId, reason);
      await fetchAllPlayers(
          search: lastPlayersSearch, status: lastPlayersStatus);
      if (selectedPlayerDetail.value != null) {
        await fetchPlayerDetailHistory(playerId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Player Blocked', 'Player access has been restricted');
    } catch (e) {
      await fetchAllPlayers(
          search: lastPlayersSearch, status: lastPlayersStatus);
      ErrorHandler.showErrorSnackBar('Block Error', e);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> unblockPlayer(String playerId) async {
    isActionLoading.value = true;

    // Instant local update so player updates/removes immediately in UI
    final index = playersList.indexWhere(
        (p) => (p['id'] ?? p['userId'] ?? '').toString() == playerId);
    if (index != -1) {
      final updatedPlayer = Map<String, dynamic>.from(playersList[index]);
      updatedPlayer['status'] = 'ACTIVE';
      updatedPlayer['isBlocked'] = false;
      playersList[index] = updatedPlayer;
      playersList.refresh();
    }

    try {
      await repository.unblockPlayer(playerId);
      await fetchAllPlayers(
          search: lastPlayersSearch, status: lastPlayersStatus);
      if (selectedPlayerDetail.value != null) {
        await fetchPlayerDetailHistory(playerId);
      }
      ErrorHandler.showSuccessSnackBar(
          'Player Unblocked', 'Player access restored');
    } catch (e) {
      await fetchAllPlayers(
          search: lastPlayersSearch, status: lastPlayersStatus);
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
