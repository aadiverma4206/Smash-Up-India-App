import '../datasources/games_remote_datasource.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/video_model.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/errors/app_exception.dart';

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
    return await remoteDataSource.getClubs(city: city);
  }

  Future<List<CourtModel>> getCourts({String? clubId}) async {
    return await remoteDataSource.getCourts(clubId: clubId);
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
    return response.data ?? [];
  }

  Future<GameModel> getGameById(String gameId) async {
    final response = await remoteDataSource.getGameById(gameId);
    if (response.data == null) {
      throw AppException('Match details not found.');
    }
    return response.data!;
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
}
