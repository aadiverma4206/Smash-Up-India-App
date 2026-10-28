import 'dart:convert';
import 'package:get/get.dart';
import '../datasources/player_remote_datasource.dart';
import '../../../data/models/player_profile_model.dart';
import '../../../data/models/player_stats_model.dart';
import '../../../data/models/player_dashboard_summary_model.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/services/auth_service.dart';

class PlayerRepository {
  final PlayerRemoteDataSource remoteDataSource;

  PlayerRepository({required this.remoteDataSource});

  String get _currentUserId => AuthService.to.currentUser.value?.id ?? 'player';

  Future<PlayerProfileModel> getProfile() async {
    final cacheKey = 'player_profile_$_currentUserId';
    try {
      final response = await remoteDataSource.getProfile();
      if (response.data == null) {
        throw AppException('Player profile data not available.');
      }
      final profile = response.data!;
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(cacheKey, jsonEncode(profile.toJson()));
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return profile;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            return PlayerProfileModel.fromJson(
                jsonDecode(cachedJson) as Map<String, dynamic>);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<PlayerProfileModel> updateProfile(
      Map<String, dynamic> updateData) async {
    final response = await remoteDataSource.updateProfile(updateData);
    if (response.data == null) {
      throw AppException('Failed to update profile.');
    }
    final profile = response.data!;
    if (Get.isRegistered<DatabaseService>()) {
      try {
        final db = Get.find<DatabaseService>();
        await db.cacheData(
            'player_profile_$_currentUserId', jsonEncode(profile.toJson()));
      } catch (_) {}
    }
    return profile;
  }

  Future<PlayerProfileModel> uploadAvatar(String filePath) async {
    final response = await remoteDataSource.uploadAvatar(filePath);
    if (response.data == null) {
      throw AppException('Failed to upload avatar.');
    }
    final profile = response.data!;
    if (Get.isRegistered<DatabaseService>()) {
      try {
        final db = Get.find<DatabaseService>();
        await db.cacheData(
            'player_profile_$_currentUserId', jsonEncode(profile.toJson()));
      } catch (_) {}
    }
    return profile;
  }

  Future<PlayerStatsModel> getStats() async {
    final cacheKey = 'player_stats_$_currentUserId';
    try {
      final response = await remoteDataSource.getStats();
      if (response.data == null) {
        throw AppException('Player statistics not available.');
      }
      final stats = response.data!;
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(cacheKey, jsonEncode(stats.toJson()));
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return stats;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            return PlayerStatsModel.fromJson(
                jsonDecode(cachedJson) as Map<String, dynamic>);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<PlayerDashboardSummaryModel> getDashboardSummary() async {
    final cacheKey = 'player_dashboard_summary_$_currentUserId';
    try {
      final response = await remoteDataSource.getDashboardSummary();
      if (response.data == null) {
        throw AppException('Dashboard summary not available.');
      }
      final summary = response.data!;
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(cacheKey, jsonEncode(summary.toJson()));
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return summary;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedJson = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            return PlayerDashboardSummaryModel.fromJson(
                jsonDecode(cachedJson) as Map<String, dynamic>);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<List<GameModel>> getMyMatches({String tab = 'UPCOMING'}) async {
    final cacheKey = 'player_my_matches_${_currentUserId}_$tab';
    try {
      final response = await remoteDataSource.getMyMatches(tab: tab);
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

  Future<List<SlotRequestModel>> getPlayerRequests(
      {String statusTab = 'ALL'}) async {
    final cacheKey = 'player_requests_${_currentUserId}_$statusTab';
    try {
      final response =
          await remoteDataSource.getPlayerRequests(statusTab: statusTab);
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

  Future<List<GameModel>> getHistory(
      {int limit = 20, int offset = 0, String? status}) async {
    final cacheKey = 'player_history_${status ?? 'ALL'}_$offset';

    try {
      final response = await remoteDataSource.getHistory(
        limit: limit,
        offset: offset,
        status: status,
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

  Future<List<NotificationModel>> getNotifications(
      {int page = 1, int limit = 20}) async {
    try {
      final response =
          await remoteDataSource.getNotifications(page: page, limit: limit);
      final list = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.upsertLocalNotifications(
              _currentUserId, list.map((n) => n.toJson()).toList());
          await db.recordOnlineSync();
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (page == 1 && Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final localRows = await db.getLocalNotifications(_currentUserId);
          if (localRows.isNotEmpty) {
            return localRows
                .map((row) => NotificationModel.fromJson(row))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await remoteDataSource.markNotificationRead(notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    await remoteDataSource.markAllNotificationsRead();
  }

  Future<void> deleteNotifications(List<String> ids,
      {bool deleteAll = false}) async {
    await remoteDataSource.deleteNotifications(ids, deleteAll: deleteAll);
  }

  Future<void> deleteNotification(String notificationId) async {
    await remoteDataSource.deleteNotification(notificationId);
  }
}
