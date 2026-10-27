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

class PlayerRepository {
  final PlayerRemoteDataSource remoteDataSource;

  PlayerRepository({required this.remoteDataSource});

  Future<PlayerProfileModel> getProfile() async {
    final response = await remoteDataSource.getProfile();
    if (response.data == null) {
      throw AppException('Player profile data not available.');
    }
    return response.data!;
  }

  Future<PlayerProfileModel> updateProfile(
      Map<String, dynamic> updateData) async {
    final response = await remoteDataSource.updateProfile(updateData);
    if (response.data == null) {
      throw AppException('Failed to update profile.');
    }
    return response.data!;
  }

  Future<PlayerProfileModel> uploadAvatar(String filePath) async {
    final response = await remoteDataSource.uploadAvatar(filePath);
    if (response.data == null) {
      throw AppException('Failed to upload avatar.');
    }
    return response.data!;
  }

  Future<PlayerStatsModel> getStats() async {
    final response = await remoteDataSource.getStats();
    if (response.data == null) {
      throw AppException('Player statistics not available.');
    }
    return response.data!;
  }

  Future<PlayerDashboardSummaryModel> getDashboardSummary() async {
    final response = await remoteDataSource.getDashboardSummary();
    if (response.data == null) {
      throw AppException('Dashboard summary not available.');
    }
    return response.data!;
  }

  Future<List<GameModel>> getMyMatches({String tab = 'UPCOMING'}) async {
    final response = await remoteDataSource.getMyMatches(tab: tab);
    return response.data ?? [];
  }

  Future<List<SlotRequestModel>> getPlayerRequests(
      {String statusTab = 'ALL'}) async {
    final response =
        await remoteDataSource.getPlayerRequests(statusTab: statusTab);
    return response.data ?? [];
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

  Future<void> deleteNotifications(List<String> ids,
      {bool deleteAll = false}) async {
    await remoteDataSource.deleteNotifications(ids, deleteAll: deleteAll);
  }

  Future<void> deleteNotification(String notificationId) async {
    await remoteDataSource.deleteNotification(notificationId);
  }
}
