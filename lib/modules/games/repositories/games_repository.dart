import 'dart:convert';
import 'package:get/get.dart';
import '../datasources/games_remote_datasource.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/video_model.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/utils/app_logger.dart';

class GamesRepository {
  final GamesRemoteDataSource remoteDataSource;

  GamesRepository({required this.remoteDataSource});

  Future<RazorpayOrderModel> createMatchOrder(double amount,
      {String? gameId}) async {
    final response =
        await remoteDataSource.createMatchOrder(amount, gameId: gameId);
    if (response.data == null) {
      throw AppException('Failed to create match payment order.');
    }
    return response.data!;
  }

  Future<List<ClubModel>> getClubs({String? city}) async {
    final cacheKey = 'clubs_list_${city ?? "all"}';
    try {
      final list = await remoteDataSource.getClubs(city: city);
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(
            cacheKey,
            jsonEncode(list.map((c) => c.toJson()).toList()),
          );
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedStr = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedStr != null && cachedStr.isNotEmpty) {
            final decoded = jsonDecode(cachedStr);
            if (decoded is List) {
              AppLogger.info('Loaded clubs from 3-day offline cache');
              return decoded
                  .map((m) => ClubModel.fromJson(Map<String, dynamic>.from(m)))
                  .toList();
            }
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<List<CourtModel>> getCourts({String? clubId}) async {
    final cacheKey = 'courts_list_${clubId ?? "all"}';
    try {
      final list = await remoteDataSource.getCourts(clubId: clubId);
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(
            cacheKey,
            jsonEncode(list.map((c) => c.toJson()).toList()),
          );
        } catch (_) {}
      }
      return list;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedStr = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedStr != null && cachedStr.isNotEmpty) {
            final decoded = jsonDecode(cachedStr);
            if (decoded is List) {
              AppLogger.info('Loaded courts from 3-day offline cache');
              return decoded
                  .map((m) => CourtModel.fromJson(Map<String, dynamic>.from(m)))
                  .toList();
            }
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<List<GameModel>> getGames({
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
    final cacheKey =
        'games_list_${city ?? "all"}_${status ?? "all"}_${myGames ?? false}_$page';
    try {
      final response = await remoteDataSource.getGames(
        city: city,
        format: format,
        skill: skill,
        date: date,
        maxEntryFee: maxEntryFee,
        status: status,
        privacy: privacy,
        court: court,
        myGames: myGames,
        page: page,
        limit: limit,
      );
      final games = response.data ?? [];
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(
            cacheKey,
            jsonEncode(games.map((g) => g.toJson()).toList()),
          );
        } catch (_) {}
      }
      return games;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedStr = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedStr != null && cachedStr.isNotEmpty) {
            final decoded = jsonDecode(cachedStr);
            if (decoded is List) {
              AppLogger.info('Loaded games from 3-day offline cache');
              return decoded
                  .map((m) => GameModel.fromJson(Map<String, dynamic>.from(m)))
                  .toList();
            }
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<GameModel> getGameById(String gameId) async {
    final cacheKey = 'game_details_$gameId';
    try {
      final response = await remoteDataSource.getGameById(gameId);
      if (response.data == null) {
        throw AppException('Match details not found.');
      }
      final game = response.data!;
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          await db.cacheData(
            cacheKey,
            jsonEncode(game.toJson()),
          );
        } catch (_) {}
      }
      return game;
    } catch (e) {
      if (Get.isRegistered<DatabaseService>()) {
        try {
          final db = Get.find<DatabaseService>();
          final cachedStr = await db.getValidCachedData(
            cacheKey,
            maxAge: const Duration(days: 3),
          );
          if (cachedStr != null && cachedStr.isNotEmpty) {
            final decoded = jsonDecode(cachedStr);
            if (decoded is Map) {
              AppLogger.info('Loaded match $gameId from 3-day offline cache');
              return GameModel.fromJson(Map<String, dynamic>.from(decoded));
            }
          }
        } catch (_) {}
      }
      if (e is AppException) rethrow;
      throw AppException('Match details not found offline.');
    }
  }

  Future<GameModel> createGame(Map<String, dynamic> gameData) async {
    final response = await remoteDataSource.createGame(gameData);
    if (response.data == null) {
      throw AppException('Failed to create game.');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> joinGame(
    String gameId,
    String position, {
    String? paymentMethod,
    String? walletPin,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final response = await remoteDataSource.joinGame(
      gameId,
      position,
      paymentMethod: paymentMethod,
      walletPin: walletPin,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> leaveGame(String gameId) async {
    final response = await remoteDataSource.leaveGame(gameId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> cancelPlayerGame(
      String gameId, String cancellationReason) async {
    final response =
        await remoteDataSource.cancelPlayerGame(gameId, cancellationReason);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> switchTeam(String gameId) async {
    final response = await remoteDataSource.switchTeam(gameId);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> joinWaitlist(
      String gameId, String position) async {
    final response = await remoteDataSource.joinWaitlist(gameId, position);
    return response.data ?? {};
  }

  Future<void> leaveWaitlist(String gameId) async {
    await remoteDataSource.leaveWaitlist(gameId);
  }

  Future<List<VideoModel>> getGameVideos(String gameId) async {
    final response = await remoteDataSource.getGameVideos(gameId);
    return response.data ?? [];
  }

  Future<List<CourtSlotModel>> getCourtAvailability(
      String courtId, String date) async {
    return await remoteDataSource.getCourtAvailability(courtId, date);
  }

  Future<List<Map<String, dynamic>>> searchPlayersForRoster(
      String gameId, String query) async {
    return await remoteDataSource.searchPlayersForRoster(gameId, query);
  }

  Future<void> addPlayerToRosterByHost(
      String gameId, String targetUserId, String team, String position) async {
    await remoteDataSource.addPlayerToRosterByHost(
        gameId, targetUserId, team, position);
  }

  Future<void> removePlayerFromRosterByHost(
      String gameId, String targetUserId) async {
    await remoteDataSource.removePlayerFromRosterByHost(gameId, targetUserId);
  }
}
