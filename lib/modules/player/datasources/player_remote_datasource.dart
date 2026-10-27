import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/player_profile_model.dart';
import '../../../data/models/player_stats_model.dart';
import '../../../data/models/player_dashboard_summary_model.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/notification_model.dart';

class PlayerRemoteDataSource {
  final DioClient dioClient;

  PlayerRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<PlayerProfileModel>> getProfile() async {
    final response = await dioClient.dio.get(ApiConstants.playerProfile);
    return ApiResponseParser.parse<PlayerProfileModel>(
      response.data,
      (json) => PlayerProfileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<PlayerProfileModel>> updateProfile(
      Map<String, dynamic> updateData) async {
    final response = await dioClient.dio.put(
      ApiConstants.playerProfile,
      data: updateData,
    );
    return ApiResponseParser.parse<PlayerProfileModel>(
      response.data,
      (json) => PlayerProfileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<PlayerProfileModel>> uploadAvatar(
      String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'profileImage': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await dioClient.dio.post(
      '/player/profile/avatar',
      data: formData,
    );

    return ApiResponseParser.parse<PlayerProfileModel>(
      response.data,
      (json) => PlayerProfileModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<PlayerStatsModel>> getStats() async {
    final response = await dioClient.dio.get(ApiConstants.playerStats);
    return ApiResponseParser.parse<PlayerStatsModel>(
      response.data,
      (json) => PlayerStatsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<PlayerDashboardSummaryModel>>
      getDashboardSummary() async {
    final response = await dioClient.dio.get('/player/dashboard-summary');
    return ApiResponseParser.parse<PlayerDashboardSummaryModel>(
      response.data,
      (json) =>
          PlayerDashboardSummaryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getMyMatches(
      {String tab = 'UPCOMING'}) async {
    final response = await dioClient.dio.get(
      '/player/my-matches',
      queryParameters: {'tab': tab},
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<SlotRequestModel>>> getPlayerRequests(
      {String statusTab = 'ALL'}) async {
    final response = await dioClient.dio.get(
      '/player/requests',
      queryParameters: {'status': statusTab},
    );
    return ApiResponseParser.parse<List<SlotRequestModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => SlotRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getHistory(
      {int limit = 20, int offset = 0, String? status}) async {
    final Map<String, dynamic> queryParams = {
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await dioClient.dio.get(
      ApiConstants.playerHistory,
      queryParameters: queryParams,
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<NotificationModel>>> getNotifications(
      {int page = 1, int limit = 20}) async {
    final response = await dioClient.dio.get(
      '/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    return ApiResponseParser.parse<List<NotificationModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markNotificationRead(String notificationId) async {
    await dioClient.dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsRead() async {
    await dioClient.dio.patch('/notifications/read-all');
  }

  Future<void> deleteNotifications(List<String> ids,
      {bool deleteAll = false}) async {
    try {
      await dioClient.dio.delete(
        '/notifications/batch',
        data: {'ids': ids, 'deleteAll': deleteAll},
      );
    } catch (_) {
      try {
        await dioClient.dio.post(
          '/notifications/batch-delete',
          data: {'ids': ids, 'deleteAll': deleteAll},
        );
      } catch (_) {}
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await dioClient.dio.delete('/notifications/$notificationId');
    } catch (_) {}
  }
}
