import 'package:json_annotation/json_annotation.dart';

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

  ManagerDashboardModel({
    required this.club,
    required this.totalRevenue,
    required this.totalBookings,
    required this.activeMatches,
    required this.occupancyRatePercentage,
    required this.onlineCctvCount,
  });

  factory ManagerDashboardModel.fromJson(Map<String, dynamic> json) {
    try {
      if (json.containsKey('totalRevenue') && json['club'] != null) {
        return _$ManagerDashboardModelFromJson(json);
      }
    } catch (_) {}
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
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
        0;
    final double revenue = rawRevenue is num
        ? rawRevenue.toDouble()
        : double.tryParse(rawRevenue.toString()) ?? 0.0;

    final rawBookings = json['totalBookings'] ?? stats?['totalBookings'] ?? 0;
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
        0;
    final int cctvCount = rawCctv is num
        ? rawCctv.toInt()
        : int.tryParse(rawCctv.toString()) ?? 0;

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
    );
  }
  Map<String, dynamic> toJson() => _$ManagerDashboardModelToJson(this);
}
