import 'package:json_annotation/json_annotation.dart';

part 'tournament_model.g.dart';

@JsonSerializable()
class TournamentModel {
  final String id;
  final String title;
  final String format;
  final String startDate;
  final String endDate;
  final double prizePool;
  final double entryFee;
  final int maxTeams;
  final int registeredTeamsCount;
  final String status;

  TournamentModel({
    required this.id,
    required this.title,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.prizePool,
    required this.entryFee,
    required this.maxTeams,
    required this.registeredTeamsCount,
    required this.status,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentModelToJson(this);
}
