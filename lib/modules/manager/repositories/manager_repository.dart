import '../datasources/manager_remote_datasource.dart';
import '../../../data/models/manager_models.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../core/errors/app_exception.dart';

class ManagerRepository {
  final ManagerRemoteDataSource remoteDataSource;

  ManagerRepository({required this.remoteDataSource});

  Future<ManagerDashboardModel> getDashboard() async {
    final response = await remoteDataSource.getDashboard();
    if (response.data == null) {
      throw AppException('Manager dashboard data not available.');
    }
    return response.data!;
  }

  Future<List<SlotRequestModel>> getPendingRequests() async {
    final response = await remoteDataSource.getPendingRequests();
    return response.data ?? [];
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

  Future<List<GameModel>> getClubMatches({String tab = 'TODAY', String? court}) async {
    final response = await remoteDataSource.getClubMatches(tab: tab, court: court);
    return response.data ?? [];
  }

  Future<List<GameModel>> getClubGames({String? court, String? tab}) async {
    final response = await remoteDataSource.getClubGames(court: court, tab: tab);
    return response.data ?? [];
  }

  Future<GameModel> updateGame(String gameId, Map<String, dynamic> gameData) async {
    final response = await remoteDataSource.updateGame(gameId, gameData);
    if (response.data == null) {
      throw AppException('Failed to update game details.');
    }
    return response.data!;
  }

  Future<GameModel> startGame(String gameId) async {
    final response = await remoteDataSource.startGame(gameId);
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
    final response = await remoteDataSource.getClubCourts();
    return response.data ?? [];
  }

  Future<List<BookingModel>> getClubBookings() async {
    final response = await remoteDataSource.getClubBookings();
    return response.data ?? [];
  }

  Future<List<GameModel>> getClubHistory({
    int limit = 20,
    int offset = 0,
    String? status,
    String? court,
  }) async {
    final response = await remoteDataSource.getClubHistory(
      limit: limit,
      offset: offset,
      status: status,
      court: court,
    );
    return response.data ?? [];
  }

  Future<List<Map<String, dynamic>>> getCourtSlots(String courtId,
      {String? date}) async {
    final response =
        await remoteDataSource.getCourtSlots(courtId, date: date);
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
    final response = await remoteDataSource.submitMatchScore(
        gameId, teamAScore, teamBScore,
        isFinal: isFinal);
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
}
