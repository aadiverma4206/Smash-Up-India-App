import '../datasources/cctv_remote_datasource.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/errors/app_exception.dart';

class CctvRepository {
  final CctvRemoteDataSource remoteDataSource;

  CctvRepository({required this.remoteDataSource});

  Future<List<CctvCameraModel>> getCameras(String clubId) async {
    final response = await remoteDataSource.getCameras(clubId);
    return response.data ?? [];
  }

  Future<CctvCameraModel> addCamera(Map<String, dynamic> data) async {
    final response = await remoteDataSource.addCamera(data);
    if (response.data == null) {
      throw AppException('Failed to add camera. No data received.');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> testCameraConnection(String cameraId) async {
    final response = await remoteDataSource.testCameraConnection(cameraId);
    return response.data ?? {};
  }

  Future<CctvRecordingModel> startRecording(String gameId,
      {int channel = 1, String? cameraId}) async {
    final response = await remoteDataSource.startRecording(
      gameId,
      channel: channel,
      cameraId: cameraId,
    );
    if (response.data == null) {
      throw AppException('Failed to start CCTV recording.');
    }
    return response.data!;
  }

  Future<CctvRecordingModel?> getRecordingByGame(String gameId) async {
    try {
      final response = await remoteDataSource.getRecordingByGame(gameId);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<CctvRecordingModel> stopRecording(String recordingId) async {
    final response = await remoteDataSource.stopRecording(recordingId);
    if (response.data == null) {
      throw AppException('Failed to stop recording.');
    }
    return response.data!;
  }

  Future<CctvRecordingModel> extendRecording(
      String recordingId, int additionalMinutes) async {
    final response =
        await remoteDataSource.extendRecording(recordingId, additionalMinutes);
    if (response.data == null) {
      throw AppException('Failed to extend recording deadline.');
    }
    return response.data!;
  }

  Future<List<CctvLiveCameraOptionModel>> getLiveCameras() async {
    final response = await remoteDataSource.getLiveCameras();
    return response.data ?? [];
  }

  Future<CctvLiveSessionModel> createLiveSession({
    required int channel,
    String streamType = 'main',
  }) async {
    final response = await remoteDataSource.createLiveSession(
      channel: channel,
      streamType: streamType,
    );
    if (response.data == null) {
      throw AppException('Could not initialize live CCTV stream session.');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> getLiveChannelStatus(int channel) async {
    final response = await remoteDataSource.getLiveChannelStatus(channel);
    return response.data ?? {};
  }

  Future<void> releaseLiveSession(String sessionId) async {
    try {
      await remoteDataSource.releaseLiveSession(sessionId);
    } catch (_) {}
  }
}
