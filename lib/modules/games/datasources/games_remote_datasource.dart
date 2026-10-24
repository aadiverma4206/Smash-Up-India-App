import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/video_model.dart';
import '../../../data/models/wallet_models.dart';

class GamesRemoteDataSource {
  final DioClient dioClient;

  GamesRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<RazorpayOrderModel>> createMatchOrder(double amount,
      {String? gameId}) async {
    final response = await dioClient.dio.post(
      '${ApiConstants.games}/order',
      data: {
        'amount': amount,
        if (gameId != null && gameId.isNotEmpty) 'gameId': gameId,
      },
    );
    return ApiResponseParser.parse<RazorpayOrderModel>(
      response.data,
      (json) => RazorpayOrderModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<ClubModel>> getClubs({String? city}) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.courts}/clubs',
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => ClubModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<CourtModel>> getCourts({String? clubId}) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.courts,
        queryParameters: {
          if (clubId != null && clubId.isNotEmpty) 'clubId': clubId,
        },
      );
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<ApiResponseModel<List<GameModel>>> getGames({
    String? city,
    String? format,
    String? skill,
    String? date,
    double? maxEntryFee,
    String? status,
    String? privacy,
    String? court,
    bool? myGames,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dioClient.dio.get(
      ApiConstants.games,
      queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (format != null && format.isNotEmpty) 'format': format,
        if (skill != null && skill.isNotEmpty) 'skill': skill,
        if (date != null && date.isNotEmpty) 'date': date,
        if (maxEntryFee != null) 'entryFee': maxEntryFee,
        if (status != null && status.isNotEmpty) 'status': status,
        if (privacy != null && privacy.isNotEmpty) 'privacy': privacy,
        if (court != null && court.isNotEmpty) 'court': court,
        if (myGames == true) 'myGames': 'true',
        'limit': limit,
        'offset': (page - 1) * limit,
      },
    );
    return ApiResponseParser.parse<List<GameModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<GameModel>> getGameById(String gameId) async {
    final response = await dioClient.dio.get('${ApiConstants.games}/$gameId');
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) {
        if (json is Map<String, dynamic>) {
          final gameData = json['game'] ?? json;
          final rosterData = json['roster'] as List?;
          final map = Map<String, dynamic>.from(gameData as Map);
          if (rosterData != null) map['roster'] = rosterData;
          return GameModel.fromJson(map);
        }
        return GameModel.fromJson(json as Map<String, dynamic>);
      },
    );
  }

  Future<ApiResponseModel<GameModel>> createGame(
      Map<String, dynamic> gameData) async {
    final response = await dioClient.dio.post(
      '${ApiConstants.games}/create',
      data: gameData,
    );
    return ApiResponseParser.parse<GameModel>(
      response.data,
      (json) => GameModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> joinGame(
    String gameId,
    String position, {
    String? paymentMethod,
    String? walletPin,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final effectiveGameId = gameId.trim();
    if (effectiveGameId.isEmpty) {
      throw Exception('Match ID is required to join');
    }
    final response = await dioClient.dio.post(
      '${ApiConstants.games}/$effectiveGameId/join',
      data: {
        'gameId': effectiveGameId,
        'position': position,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
        if (walletPin != null && walletPin.isNotEmpty) 'walletPin': walletPin,
        if (razorpayOrderId != null && razorpayOrderId.isNotEmpty)
          'razorpayOrderId': razorpayOrderId,
        if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty)
          'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null && razorpaySignature.isNotEmpty)
          'razorpaySignature': razorpaySignature,
      },
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> leaveGame(
      String gameId) async {
    final response =
        await dioClient.dio.post('${ApiConstants.games}/$gameId/leave');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> cancelPlayerGame(
      String gameId, String cancellationReason) async {
    final response = await dioClient.dio.post(
      '${ApiConstants.games}/$gameId/cancel',
      data: {'cancellationReason': cancellationReason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> switchTeam(
      String gameId) async {
    final response =
        await dioClient.dio.post('${ApiConstants.games}/$gameId/switch-team');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> joinWaitlist(
      String gameId, String position) async {
    final response = await dioClient.dio.post(
      '${ApiConstants.games}/$gameId/waitlist',
      data: {'position': position},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<void>> leaveWaitlist(String gameId) async {
    final response =
        await dioClient.dio.delete('${ApiConstants.games}/$gameId/waitlist');
    return ApiResponseParser.parse<void>(response.data, (_) {});
  }

  Future<ApiResponseModel<List<VideoModel>>> getGameVideos(
      String gameId) async {
    final response =
        await dioClient.dio.get('${ApiConstants.games}/$gameId/videos');
    return ApiResponseParser.parse<List<VideoModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<CourtSlotModel>> getCourtAvailability(
      String courtId, String date) async {
    final List<CourtSlotModel> slots = [];
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.courts}/$courtId/availability',
        queryParameters: {'date': date},
      );
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final list = (response.data['data'] as List)
            .map((e) => CourtSlotModel.fromJson(e as Map<String, dynamic>))
            .where((s) => s.bookingDate.isEmpty || s.bookingDate == date)
            .where((s) =>
                s.status.toUpperCase() != 'CANCELLED' &&
                s.status.toUpperCase() != 'REJECTED')
            .toList();
        slots.addAll(list);
      }
    } catch (_) {}

    if (slots.isEmpty) {
      try {
        final response = await dioClient.dio.get(
          '/manager/courts/$courtId/slots',
          queryParameters: {'date': date},
        );
        final raw = response.data is Map
            ? response.data['data'] ?? response.data['slots']
            : response.data;
        if (raw is List) {
          final list = raw.map((e) {
            final map = e as Map<String, dynamic>;
            final matchDate = (map['matchDate'] ??
                    map['match_date'] ??
                    map['bookingDate'] ??
                    map['booking_date'] ??
                    date)
                .toString();
            return CourtSlotModel(
              id: (map['id'] ?? map['gameId'] ?? '').toString(),
              courtId: courtId,
              bookingDate: matchDate,
              startTime:
                  (map['startTime'] ?? map['start_time'] ?? '').toString(),
              endTime: (map['endTime'] ?? map['end_time'] ?? '').toString(),
              status: (map['status'] ?? 'CONFIRMED').toString(),
              title:
                  (map['title'] ?? map['gameTitle'] ?? 'Booked Match').toString(),
              source: 'GAME',
            );
          }).where((s) => s.bookingDate == date)
            .where((s) =>
                s.status.toUpperCase() != 'CANCELLED' &&
                s.status.toUpperCase() != 'REJECTED')
            .toList();
          slots.addAll(list);
        }
      } catch (_) {}
    }

    return slots;
  }
}
