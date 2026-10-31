import 'package:json_annotation/json_annotation.dart';

part 'player_stats_model.g.dart';

@JsonSerializable(createFactory: false)
class PlayerStatsModel {
  final int matchesJoined;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesDrawn;
  final int goalsScored;
  final int assists;
  final int motmCount;
  final double winRatePercentage;
  final List<DynamicStatCustomItem>? customStats;

  PlayerStatsModel({
    this.matchesJoined = 0,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.matchesDrawn = 0,
    this.goalsScored = 0,
    this.assists = 0,
    this.motmCount = 0,
    this.winRatePercentage = 0.0,
    this.customStats,
  });

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    }
    return 0;
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    List<DynamicStatCustomItem>? customList;
    if (json['customStats'] is List) {
      customList = (json['customStats'] as List)
          .map((e) => DynamicStatCustomItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['custom_stats'] is List) {
      customList = (json['custom_stats'] as List)
          .map((e) => DynamicStatCustomItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PlayerStatsModel(
      matchesJoined: _toInt(json['matchesJoined'] ??
          json['matches_joined'] ??
          json['joinedMatches'] ??
          json['joined_matches']),
      matchesPlayed: _toInt(json['matchesPlayed'] ?? json['matches_played']),
      matchesWon: _toInt(json['matchesWon'] ?? json['matches_won']),
      matchesLost: _toInt(json['matchesLost'] ?? json['matches_lost']),
      matchesDrawn: _toInt(json['matchesDrawn'] ?? json['matches_drawn']),
      goalsScored: _toInt(json['goalsScored'] ?? json['goals_scored']),
      assists: _toInt(json['assists']),
      motmCount: _toInt(json['motmCount'] ?? json['motm_count']),
      winRatePercentage: _toDouble(
          json['winRatePercentage'] ?? json['win_rate_percentage']),
      customStats: customList,
    );
  }
  Map<String, dynamic> toJson() => _$PlayerStatsModelToJson(this);
}

class DynamicStatCustomItem {
  final String key;
  final String label;
  final String value;
  final String? icon;

  DynamicStatCustomItem({
    required this.key,
    required this.label,
    required this.value,
    this.icon,
  });

  factory DynamicStatCustomItem.fromJson(Map<String, dynamic> json) {
    return DynamicStatCustomItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '0',
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'icon': icon,
      };
}
