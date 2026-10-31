import 'dart:convert';
import 'package:get/get.dart';
import '../datasources/manager_remote_datasource.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/services/auth_service.dart';

class ManagerRepository {
  final ManagerRemoteDataSource remoteDataSource;

  ManagerRepository({required this.remoteDataSource});

  String get _currentUserId =>
      AuthService.to.currentUser.value?.id ?? 'manager';

  Future<ManagerDashboardModel> getDashboard() async {
    final cacheKey = 'manager_dashboard_$_currentUserId';
    try {
      final response = await remoteDataSource.getDashboard();
      if (response.data == null) {
        throw AppException('Manager dashboard data not available.');
      }
      final dashboard = response.data!;
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(cacheKey, jsonEncode(dashboard.toJson()));
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return dashboard;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            return ManagerDashboardModel.fromJson(
                jsonDecode(cachedJson) as Map<String, dynamic>);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClubMetrics() async {
    final cacheKey = 'manager_metrics_$_currentUserId';
    try {
      final response = await remoteDataSource.getClubMetrics();
      final metrics = response.data ?? {};
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(cacheKey, jsonEncode(metrics));
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return metrics;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            return jsonDecode(cachedJson) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
      return {};
    }
  }

  Future<List<SlotRequestModel>> getPendingRequests() async {
    final cacheKey = 'manager_pending_requests_$_currentUserId';
    try {
      final response = await remoteDataSource.getPendingRequests();
      final list = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final jsonPayload = jsonEncode(list.map((r) => r.toJson()).toList());
          await db.cacheData(cacheKey, jsonPayload);
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded
                .map((item) =>
                    SlotRequestModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> approveSlotRequest(String requestId) async {
    final response = await remoteDataSource.approveSlotRequest(requestId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> rejectSlotRequest(
      String requestId, String rejectionReason) async {
    final response =
        await remoteDataSource.rejectSlotRequest(requestId, rejectionReason);
    return response.data ?? {};
  }

  Future<List<GameModel>> getClubMatches(
      {String tab = 'TODAY', String? court}) async {
    final cacheKey =
        'manager_club_matches_${_currentUserId}_${tab}_${court ?? 'ALL'}';
    try {
      final response =
          await remoteDataSource.getClubMatches(tab: tab, court: court);
      final list = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final jsonPayload = jsonEncode(list.map((g) => g.toJson()).toList());
          await db.cacheData(cacheKey, jsonPayload);
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded
                .map((item) => GameModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<List<GameModel>> getClubGames({String? court, String? tab}) async {
    final response =
        await remoteDataSource.getClubGames(court: court, tab: tab);
    return response.data ?? [];
  }

  Future<GameModel> getGameDetails(String gameId) async {
    final response = await remoteDataSource.getGameDetails(gameId);
    if (response.data == null) {
      throw AppException('Failed to load game details.');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> getGamePlayers(String gameId) async {
    final response = await remoteDataSource.getGamePlayers(gameId);
    return response.data ?? {};
  }

  Future<GameModel> updateGame(
      String gameId, Map<String, dynamic> gameData) async {
    final response = await remoteDataSource.updateGame(gameId, gameData);
    if (response.data == null) {
      throw AppException('Failed to update game details.');
    }
    return response.data!;
  }

  Future<GameModel> rescheduleGame(
    String gameId, {
    required String matchDate,
    required String startTime,
    required String endTime,
    String? courtId,
    String? reason,
  }) async {
    final response = await remoteDataSource.rescheduleGame(
      gameId,
      matchDate: matchDate,
      startTime: startTime,
      endTime: endTime,
      courtId: courtId,
      reason: reason,
    );
    if (response.data == null) {
      throw AppException('Failed to reschedule match.');
    }
    return response.data!;
  }

  Future<GameModel> startGame(String gameId, {int? durationMinutes}) async {
    final response = await remoteDataSource.startGame(gameId,
        durationMinutes: durationMinutes);
    if (response.data == null) {
      throw AppException('Failed to start match.');
    }
    return response.data!;
  }

  Future<GameModel> completeGame(
      String gameId, int teamAScore, int teamBScore) async {
    final response =
        await remoteDataSource.completeGame(gameId, teamAScore, teamBScore);
    if (response.data == null) {
      throw AppException('Failed to complete match.');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> cancelGameWithRefunds(
      String gameId, String cancellationReason) async {
    final response = await remoteDataSource.cancelGameWithRefunds(
        gameId, cancellationReason);
    return response.data ?? {};
  }

  Future<List<GameActivityLogModel>> getActivityLogs(String gameId) async {
    final response = await remoteDataSource.getActivityLogs(gameId);
    return response.data ?? [];
  }

  Future<List<CourtModel>> getClubCourts() async {
    final cacheKey = 'manager_courts_$_currentUserId';
    try {
      final response = await remoteDataSource.getClubCourts();
      final list = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final jsonPayload = jsonEncode(list.map((c) => c.toJson()).toList());
          await db.cacheData(cacheKey, jsonPayload);
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded
                .map(
                    (item) => CourtModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<CourtModel> updateCourtPricing({
    required String courtId,
    double? basePrice,
    String? status,
    double? peakMultiplier,
    double? weekendMultiplier,
  }) async {
    final response = await remoteDataSource.updateCourtPricing(
      courtId: courtId,
      basePrice: basePrice,
      status: status,
      peakMultiplier: peakMultiplier,
      weekendMultiplier: weekendMultiplier,
    );
    if (response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<List<BookingModel>> getClubBookings() async {
    final cacheKey = 'manager_bookings_$_currentUserId';
    try {
      final response = await remoteDataSource.getClubBookings();
      final list = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final jsonPayload = jsonEncode(list.map((b) => b.toJson()).toList());
          await db.cacheData(cacheKey, jsonPayload);
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded
                .map((item) =>
                    BookingModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<List<GameModel>> getClubHistory({
    int limit = 20,
    int offset = 0,
    String? status,
    String? court,
  }) async {
    final cacheKey =
        'match_history_${status ?? 'ALL'}_${court ?? 'ALL'}_$offset';

    try {
      final response = await remoteDataSource.getClubHistory(
        limit: limit,
        offset: offset,
        status: status,
        court: court,
      );

      final list = response.data ?? [];

      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final jsonPayload = jsonEncode(list.map((g) => g.toJson()).toList());
          await db.cacheData(cacheKey, jsonPayload);
          await db.pruneExpiredCache(maxAge: const Duration(days: 3));
        } catch (_) {}
      }

      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );

          if (cachedJson != null && cachedJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded
                .map((item) => GameModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }

      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCourtSlots(String courtId,
      {String? date}) async {
    final response = await remoteDataSource.getCourtSlots(courtId, date: date);
    return response.data ?? [];
  }

  Future<List<GameModel>> getPendingPlayerGames() async {
    final response = await remoteDataSource.getPendingPlayerGames();
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> approvePlayerGame(String gameId) async {
    final response = await remoteDataSource.approvePlayerGame(gameId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> rejectPlayerGame(
      String gameId, String rejectionReason) async {
    final response =
        await remoteDataSource.rejectPlayerGame(gameId, rejectionReason);
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getAllPlayers({
    String? search,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await remoteDataSource.getAllPlayers(
      search: search,
      status: status,
      limit: limit,
      offset: offset,
    );
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> getPlayerDetailHistory(String playerId) async {
    final response = await remoteDataSource.getPlayerDetailHistory(playerId);
    return response.data ?? {};
  }

  Future<List<NotificationModel>> getNotifications(
      {int page = 1, int limit = 50}) async {
    final response =
        await remoteDataSource.getNotifications(page: page, limit: limit);
    return response.data ?? [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    await remoteDataSource.markNotificationRead(notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    await remoteDataSource.markAllNotificationsRead();
  }

  Future<Map<String, dynamic>> blockPlayer(
      String playerId, String reason) async {
    final response = await remoteDataSource.blockPlayer(playerId, reason);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> unblockPlayer(String playerId) async {
    final response = await remoteDataSource.unblockPlayer(playerId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> submitMatchScore(
      String gameId, int teamAScore, int teamBScore,
      {bool isFinal = true}) async {
    final response = await remoteDataSource
        .submitMatchScore(gameId, teamAScore, teamBScore, isFinal: isFinal);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getMatchRecording(String gameId) async {
    final response = await remoteDataSource.getMatchRecording(gameId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> stopMatchRecording(String gameId) async {
    final response = await remoteDataSource.stopMatchRecording(gameId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> extendMatchTime(String gameId,
      {int additionalMinutes = 15}) async {
    final response = await remoteDataSource.extendMatchTime(gameId,
        additionalMinutes: additionalMinutes);
    return response.data ?? {};
  }
}
