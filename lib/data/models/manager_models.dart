import 'package:json_annotation/json_annotation.dart';
import 'game_model.dart';

part 'manager_models.g.dart';

@JsonSerializable()
class ManagerClubModel {
  final String id;
  final String name;
  final String city;
  final String address;
  final String status;

  ManagerClubModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.status,
  });

  factory ManagerClubModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return ManagerClubModel(
          id: '', name: '', city: '', address: '', status: 'ACTIVE');
    }
    try {
      return _$ManagerClubModelFromJson(json);
    } catch (_) {
      return ManagerClubModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        status: (json['status'] ?? 'ACTIVE').toString(),
      );
    }
  }
  Map<String, dynamic> toJson() => _$ManagerClubModelToJson(this);
}

@JsonSerializable()
class ManagerDashboardModel {
  final ManagerClubModel club;
  final double totalRevenue;
  final int totalBookings;
  final int activeMatches;
  final double occupancyRatePercentage;
  final int onlineCctvCount;
  final int totalPlayers;
  final int totalCourts;
  final int futureBookings;
  final int completedMatches;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final GameModel? court1Match;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final GameModel? court2Match;

  ManagerDashboardModel({
    required this.club,
    required this.totalRevenue,
    required this.totalBookings,
    required this.activeMatches,
    required this.occupancyRatePercentage,
    required this.onlineCctvCount,
    this.totalPlayers = 0,
    this.totalCourts = 2,
    this.futureBookings = 0,
    this.completedMatches = 0,
    this.court1Match,
    this.court2Match,
  });

  factory ManagerDashboardModel.fromJson(Map<String, dynamic> json) {
    GameModel? c1Match;
    GameModel? c2Match;

    if (json['court1Match'] is Map<String, dynamic>) {
      try {
        c1Match = GameModel.fromJson(json['court1Match'] as Map<String, dynamic>);
      } catch (_) {}
    }
    if (json['court2Match'] is Map<String, dynamic>) {
      try {
        c2Match = GameModel.fromJson(json['court2Match'] as Map<String, dynamic>);
      } catch (_) {}
    }
    if (json['courtMatches'] is Map<String, dynamic>) {
      final cm = json['courtMatches'] as Map<String, dynamic>;
      if (c1Match == null && cm['court1'] is Map<String, dynamic>) {
        try {
          c1Match = GameModel.fromJson(cm['court1'] as Map<String, dynamic>);
        } catch (_) {}
      }
      if (c2Match == null && cm['court2'] is Map<String, dynamic>) {
        try {
          c2Match = GameModel.fromJson(cm['court2'] as Map<String, dynamic>);
        } catch (_) {}
      }
    }

    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : null;
    final metrics = json['metrics'] is Map<String, dynamic>
        ? json['metrics'] as Map<String, dynamic>
        : null;
    final cctvStats = stats?['cctvStats'] is Map<String, dynamic>
        ? stats!['cctvStats'] as Map<String, dynamic>
        : (json['cctvStats'] is Map<String, dynamic>
            ? json['cctvStats'] as Map<String, dynamic>
            : null);

    final rawRevenue = json['totalRevenue'] ??
        json['totalRevenueRupees'] ??
        stats?['totalRevenueRupees'] ??
        stats?['totalRevenue'] ??
        metrics?['revenue'] ??
        0;
    final double revenue = rawRevenue is num
        ? rawRevenue.toDouble()
        : double.tryParse(rawRevenue.toString()) ?? 0.0;

    final rawBookings = json['totalBookings'] ??
        stats?['totalBookings'] ??
        metrics?['bookings'] ??
        0;
    final int bookings = rawBookings is num
        ? rawBookings.toInt()
        : int.tryParse(rawBookings.toString()) ?? 0;

    final rawActiveMatches = json['activeMatches'] ??
        stats?['activeMatches'] ??
        stats?['activeGames'] ??
        stats?['totalGames'] ??
        0;
    final int matches = rawActiveMatches is num
        ? rawActiveMatches.toInt()
        : int.tryParse(rawActiveMatches.toString()) ?? 0;

    final rawOccupancy = json['occupancyRatePercentage'] ??
        stats?['occupancyRatePercentage'] ??
        0.0;
    final double occupancy = rawOccupancy is num
        ? rawOccupancy.toDouble()
        : double.tryParse(rawOccupancy.toString()) ?? 0.0;

    final rawCctv = json['onlineCctvCount'] ??
        cctvStats?['onlineCameras'] ??
        stats?['onlineCameras'] ??
        stats?['onlineCctvCount'] ??
        metrics?['cctvOnline'] ??
        0;
    final int cctvCount = rawCctv is num
        ? rawCctv.toInt()
        : int.tryParse(rawCctv.toString()) ?? 0;

    final rawPlayers = json['totalPlayers'] ??
        metrics?['players'] ??
        json['players'] ??
        0;
    final int players = rawPlayers is num
        ? rawPlayers.toInt()
        : int.tryParse(rawPlayers.toString()) ?? 0;

    final rawCourts = json['totalCourts'] ??
        metrics?['courts'] ??
        json['courts'] ??
        stats?['totalCourts'] ??
        2;
    final int courts = rawCourts is num
        ? rawCourts.toInt()
        : int.tryParse(rawCourts.toString()) ?? 2;

    final rawFutureBookings = json['futureBookings'] ??
        metrics?['futureBookings'] ??
        metrics?['bookings'] ??
        json['totalBookings'] ??
        stats?['totalBookings'] ??
        0;
    final int fBookings = rawFutureBookings is num
        ? rawFutureBookings.toInt()
        : int.tryParse(rawFutureBookings.toString()) ?? 0;

    final rawCompleted = json['completedMatches'] ??
        metrics?['completedMatches'] ??
        stats?['completedMatches'] ??
        0;
    final int completed = rawCompleted is num
        ? rawCompleted.toInt()
        : int.tryParse(rawCompleted.toString()) ?? 0;

    final clubJson = json['club'] is Map<String, dynamic>
        ? json['club'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ManagerDashboardModel(
      club: ManagerClubModel.fromJson(clubJson),
      totalRevenue: revenue,
      totalBookings: bookings,
      activeMatches: matches,
      occupancyRatePercentage: occupancy,
      onlineCctvCount: cctvCount,
      totalPlayers: players,
      totalCourts: courts,
      futureBookings: fBookings,
      completedMatches: completed,
      court1Match: c1Match,
      court2Match: c2Match,
    );
  }
  Map<String, dynamic> toJson() => _$ManagerDashboardModelToJson(this);
}
