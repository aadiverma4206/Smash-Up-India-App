import 'package:json_annotation/json_annotation.dart';

part 'video_model.g.dart';

@JsonSerializable(createFactory: false)
class VideoModel {
  final String id;
  final String gameId;
  final String? cctvId;
  final String cameraName;
  final String title;
  final String clubName;
  final String courtName;
  final String matchDate;
  final String playbackUrl;
  final int durationSeconds;

  VideoModel({
    required this.id,
    required this.gameId,
    this.cctvId,
    this.cameraName = 'CCTV Camera',
    required this.title,
    required this.clubName,
    required this.courtName,
    required this.matchDate,
    required this.playbackUrl,
    this.durationSeconds = 5400,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: (json['id'] ?? json['video_id'] ?? '').toString(),
      gameId: (json['gameId'] ?? json['game_id'] ?? '').toString(),
      cctvId: json['cctvId']?.toString() ??
          json['cctv_id']?.toString() ??
          json['cameraId']?.toString() ??
          json['camera_id']?.toString(),
      cameraName: (json['cameraName'] ??
              json['camera_name'] ??
              json['cctvName'] ??
              json['cctv_name'] ??
              'CCTV Camera')
          .toString(),
      title: (json['title'] ?? 'Match Recording').toString(),
      clubName:
          (json['clubName'] ?? json['club_name'] ?? 'Arena Club').toString(),
      courtName:
          (json['courtName'] ?? json['court_name'] ?? 'Court 1').toString(),
      matchDate: (json['matchDate'] ?? json['match_date'] ?? '').toString(),
      playbackUrl: (json['playbackUrl'] ??
              json['videoUrl'] ??
              json['video_url'] ??
              json['url'] ??
              '')
          .toString(),
      durationSeconds:
          (json['durationSeconds'] ?? json['duration_seconds'] ?? 5400) as int,
    );
  }

  Map<String, dynamic> toJson() => _$VideoModelToJson(this);
}
