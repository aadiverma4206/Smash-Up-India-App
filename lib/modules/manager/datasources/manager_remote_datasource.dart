import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/notification_model.dart';

class ManagerRemoteDataSource {
  final DioClient dioClient;

  ManagerRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<ManagerDashboardModel>> getDashboard() async {
    final response = await dioClient.dio.get('/manager/dashboard');
    return ApiResponseParser.parse<ManagerDashboardModel>(
      response.data,
      (json) => ManagerDashboardModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<List<SlotRequestModel>>> getPendingRequests() async {
    final response = await dioClient.dio.get('/manager/requests');
    return ApiResponseParser.parse<List<SlotRequestModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => SlotRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> approveSlotRequest(
      String requestId) async {
    final response =
        await dioClient.dio.post('/manager/requests/$requestId/approve');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> rejectSlotRequest(
      String requestId, String rejectionReason) async {
    final response = await dioClient.dio.post(
      '/manager/requests/$requestId/reject',
      data: {'rejectionReason': rejectionReason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getClubMatches(
      {String tab = 'TODAY', String? court}) async {
    final response = await dioClient.dio.get(
      '/manager/matches',
      queryParameters: {
        'tab': tab,
        if (court != null && court.isNotEmpty) 'court': court,
      },
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getClubGames(
      {String? court, String? tab}) async {
    final response = await dioClient.dio.get(
      '/manager/games',
      queryParameters: {
        if (court != null && court.isNotEmpty) 'court': court,
        if (tab != null && tab.isNotEmpty) 'tab': tab,
      },
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<GameModel>> updateGame(
      String gameId, Map<String, dynamic> gameData) async {
    final response = await dioClient.dio.put(
      '/manager/games/$gameId',
      data: gameData,
    );
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) => GameModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<GameModel>> rescheduleGame(
    String gameId, {
    required String matchDate,
    required String startTime,
    required String endTime,
    String? courtId,
    String? reason,
  }) async {
    final response = await dioClient.dio.post(
      '/manager/games/$gameId/reschedule',
      data: {
        'matchDate': matchDate,
        'startTime': startTime,
        'endTime': endTime,
        if (courtId != null && courtId.isNotEmpty) 'courtId': courtId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) => GameModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<GameModel>> startGame(String gameId) async {
    final response = await dioClient.dio.post('/manager/games/$gameId/start');
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) => GameModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<GameModel>> completeGame(
      String gameId, int teamAScore, int teamBScore) async {
    final response = await dioClient.dio.post(
      '/manager/games/$gameId/complete',
      data: {'teamAScore': teamAScore, 'teamBScore': teamBScore},
    );
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) => GameModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> cancelGameWithRefunds(
      String gameId, String cancellationReason) async {
    final response = await dioClient.dio.post(
      '/manager/games/$gameId/cancel',
      data: {'cancellationReason': cancellationReason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<List<GameActivityLogModel>>> getActivityLogs(
      String gameId) async {
    final response = await dioClient.dio.get('/games/$gameId/activity');
    return ApiResponseParser.parse<List<GameActivityLogModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<CourtModel>>> getClubCourts() async {
    final response = await dioClient.dio.get('/manager/courts');
    return ApiResponseParser.parse<List<CourtModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<BookingModel>>> getClubBookings() async {
    final response = await dioClient.dio.get('/manager/bookings');
    return ApiResponseParser.parse<List<BookingModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getClubHistory({
    int limit = 20,
    int offset = 0,
    String? status,
    String? court,
  }) async {
    final response = await dioClient.dio.get(
      '/manager/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (status != null && status != 'ALL') 'status': status,
        if (court != null && court != 'ALL') 'court': court,
      },
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<List<Map<String, dynamic>>>> getCourtSlots(
      String courtId,
      {String? date}) async {
    final response = await dioClient.dio.get(
      '/manager/courts/$courtId/slots',
      queryParameters: date != null ? {'date': date} : null,
    );
    return ApiResponseParser.parse<List<Map<String, dynamic>>>(
      response.data,
      (json) {
        if (json is Map<String, dynamic> && json['slots'] is List) {
          return (json['slots'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        if (json is List) {
          return json.map((e) => e as Map<String, dynamic>).toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<ApiResponseModel<List<GameModel>>> getPendingPlayerGames() async {
    final response = await dioClient.dio.get('/manager/games/pending');
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> approvePlayerGame(
      String gameId) async {
    final response = await dioClient.dio.post('/manager/games/$gameId/approve');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> rejectPlayerGame(
      String gameId, String rejectionReason) async {
    final response = await dioClient.dio.post(
      '/manager/games/$gameId/reject',
      data: {'rejectionReason': rejectionReason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<List<Map<String, dynamic>>>> getAllPlayers({
    String? search,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await dioClient.dio.get(
      '/manager/players',
      queryParameters: {
        if (search != null) 'search': search,
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return ApiResponseParser.parse<List<Map<String, dynamic>>>(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => e as Map<String, dynamic>).toList();
        }
        if (json is Map<String, dynamic> && json['players'] is List) {
          return (json['players'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        if (json is Map<String, dynamic> && json['data'] is List) {
          return (json['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> getPlayerDetailHistory(
      String playerId) async {
    final response = await dioClient.dio.get('/manager/players/$playerId');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<List<NotificationModel>>> getNotifications(
      {int page = 1, int limit = 50}) async {
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

  Future<ApiResponseModel<Map<String, dynamic>>> blockPlayer(
      String playerId, String reason) async {
    final response = await dioClient.dio.post(
      '/manager/players/$playerId/block',
      data: {'reason': reason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> unblockPlayer(
      String playerId) async {
    final response =
        await dioClient.dio.post('/manager/players/$playerId/unblock');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> submitMatchScore(
      String gameId, int teamAScore, int teamBScore,
      {bool isFinal = true}) async {
    final response = await dioClient.dio.post(
      '/manager/games/$gameId/score',
      data: {
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'isFinal': isFinal,
      },
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> getMatchRecording(
      String gameId) async {
    final response =
        await dioClient.dio.get('/manager/games/$gameId/recording');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> stopMatchRecording(
      String gameId) async {
    final response =
        await dioClient.dio.post('/manager/games/$gameId/recording/stop');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }
}
