import 'package:json_annotation/json_annotation.dart';

part 'cctv_models.g.dart';

@JsonSerializable()
class CctvCameraModel {
  final String id;
  final String clubId;
  final String? courtId;
  final String? courtName;
  final String name;
  final String cameraType; // RTSP_DOME, ONVIF
  final String connectionType; // RTSP
  final String? ipAddress;
  final int port;
  final bool isEnabled;
  final String status; // ONLINE, OFFLINE
  final String healthStatus; // ONLINE, OFFLINE
  final String? lastSeenAt;

  CctvCameraModel({
    required this.id,
    required this.clubId,
    this.courtId,
    this.courtName,
    required this.name,
    this.cameraType = 'RTSP_DOME',
    this.connectionType = 'RTSP',
    this.ipAddress,
    this.port = 554,
    this.isEnabled = true,
    this.status = 'ONLINE',
    this.healthStatus = 'ONLINE',
    this.lastSeenAt,
  });

  factory CctvCameraModel.fromJson(Map<String, dynamic> json) =>
      _$CctvCameraModelFromJson(json);
  Map<String, dynamic> toJson() => _$CctvCameraModelToJson(this);
}

@JsonSerializable()
class CctvRecordingModel {
  final String id;
  final String gameId;
  final String clubId;
  final String? courtId;
  final String? cameraId;
  final String status;
  final String recordingStatus;
  final String startedAt;
  final String scheduledMatchEnd;
  final String stopDeadline;
  final String? actualStopTime;
  final bool manualStop;

  CctvRecordingModel({
    required this.id,
    required this.gameId,
    required this.clubId,
    this.courtId,
    this.cameraId,
    required this.status,
    required this.recordingStatus,
    required this.startedAt,
    required this.scheduledMatchEnd,
    required this.stopDeadline,
    this.actualStopTime,
    this.manualStop = false,
  });

  factory CctvRecordingModel.fromJson(Map<String, dynamic> json) =>
      _$CctvRecordingModelFromJson(json);
  Map<String, dynamic> toJson() => _$CctvRecordingModelToJson(this);
}

@JsonSerializable()
class CctvLiveCameraOptionModel {
  final String id;
  final int channel;
  final String name;
  final String? courtName;
  final String status; // ONLINE, OFFLINE, CONNECTING, FAILED
  final String healthStatus;
  final String? ipAddress;
  final int port;
  final String protocol;

  CctvLiveCameraOptionModel({
    required this.id,
    required this.channel,
    required this.name,
    this.courtName,
    this.status = 'ONLINE',
    this.healthStatus = 'ONLINE',
    this.ipAddress,
    this.port = 554,
    this.protocol = 'rtsp',
  });

  factory CctvLiveCameraOptionModel.fromJson(Map<String, dynamic> json) =>
      _$CctvLiveCameraOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$CctvLiveCameraOptionModelToJson(this);
}

/// Live CCTV session returned by the backend after calling POST /cctv/live/session.
///
/// The backend transcodes the RTSP camera stream to HLS using FFmpeg and returns
/// an HLS URL (.m3u8) in [rtspUrl] and [hlsUrl]. Flutter's video_player package
/// plays HLS natively on Android and iOS. Raw RTSP is NOT supported by video_player.
@JsonSerializable()
class CctvLiveSessionModel {
  final String sessionId;
  final int channel;
  final String cameraName;
  final String streamType; // main, sub
  final String status; // ONLINE, OFFLINE

  final int latencyMs;

  /// URL of the HLS playlist (.m3u8) served by the backend.
  /// Use this with VideoPlayerController.networkUrl() in Flutter.
  /// Kept as 'rtspUrl' in JSON for backward compatibility.
  @JsonKey(name: 'rtspUrl')
  final String rtspUrl;

  /// Explicit HLS URL field. Same value as rtspUrl when FFmpeg is available.
  @JsonKey(name: 'hlsUrl', defaultValue: '')
  final String hlsUrl;

  /// Whether FFmpeg HLS transcoding is active on the backend.
  @JsonKey(name: 'hlsReady', defaultValue: false)
  final bool hlsReady;

  final String expiresAt;

  CctvLiveSessionModel({
    required this.sessionId,
    required this.channel,
    required this.cameraName,
    this.streamType = 'main',
    required this.status,
    this.latencyMs = 0,
    required this.rtspUrl,
    this.hlsUrl = '',
    this.hlsReady = false,
    required this.expiresAt,
  });

  /// Returns the best URL to use for video playback.
  /// Prefers [hlsUrl] if available, falls back to [rtspUrl].
  String get playbackUrl {
    if (hlsUrl.isNotEmpty) return hlsUrl;
    if (rtspUrl.isNotEmpty) return rtspUrl;
    return '';
  }

  factory CctvLiveSessionModel.fromJson(Map<String, dynamic> json) =>
      _$CctvLiveSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$CctvLiveSessionModelToJson(this);
}
