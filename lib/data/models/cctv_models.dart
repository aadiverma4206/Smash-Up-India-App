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
  final String
      status; // RECORDING, POST_MATCH, STOPPED_MANUALLY, COMPLETED, FAILED
  final String
      recordingStatus; // RECORDING, POST_MATCH, STOPPED_MANUALLY, COMPLETED, FAILED
  final String startedAt;
  final String scheduledMatchEnd;
  final String stopDeadline; // scheduled match end + 15 min
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

@JsonSerializable()
class CctvLiveSessionModel {
  final String sessionId;
  final int channel;
  final String cameraName;
  final String streamType; // main, sub
  final String status; // ONLINE, OFFLINE
  final int latencyMs;
  final String rtspUrl;
  final String expiresAt;

  CctvLiveSessionModel({
    required this.sessionId,
    required this.channel,
    required this.cameraName,
    this.streamType = 'main',
    required this.status,
    this.latencyMs = 0,
    required this.rtspUrl,
    required this.expiresAt,
  });

  factory CctvLiveSessionModel.fromJson(Map<String, dynamic> json) =>
      _$CctvLiveSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$CctvLiveSessionModelToJson(this);
}
