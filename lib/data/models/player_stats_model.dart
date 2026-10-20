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

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    final int played =
        (json['matchesPlayed'] ?? json['matches_played'] as num?)?.toInt() ?? 0;
    final int joined = (json['matchesJoined'] ??
                json['matches_joined'] ??
                json['joinedMatches'] ??
                json['joined_matches'] as num?)
            ?.toInt() ??
        played;

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
      matchesJoined: joined,
      matchesPlayed: played,
      matchesWon:
          (json['matchesWon'] ?? json['matches_won'] as num?)?.toInt() ?? 0,
      matchesLost:
          (json['matchesLost'] ?? json['matches_lost'] as num?)?.toInt() ?? 0,
      matchesDrawn:
          (json['matchesDrawn'] ?? json['matches_drawn'] as num?)?.toInt() ?? 0,
      goalsScored:
          (json['goalsScored'] ?? json['goals_scored'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      motmCount:
          (json['motmCount'] ?? json['motm_count'] as num?)?.toInt() ?? 0,
      winRatePercentage:
          (json['winRatePercentage'] ?? json['win_rate_percentage'] as num?)
                  ?.toDouble() ??
              0.0,
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
