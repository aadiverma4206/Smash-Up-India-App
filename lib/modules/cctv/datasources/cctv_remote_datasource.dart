import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/constants/api_constants.dart';

class CctvRemoteDataSource {
  final DioClient dioClient;

  CctvRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<List<CctvCameraModel>>> getCameras(
      String clubId) async {
    final response = await dioClient.dio
        .get(ApiConstants.cctvCameras, queryParameters: {'clubId': clubId});
    return ApiResponseParser.parse<List<CctvCameraModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => CctvCameraModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<CctvCameraModel>> addCamera(
      Map<String, dynamic> data) async {
    final response =
        await dioClient.dio.post(ApiConstants.cctvCameras, data: data);
    return ApiResponseParser.parse<CctvCameraModel>(
      response.data,
      (json) => CctvCameraModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> testCameraConnection(
      String cameraId) async {
    final response =
        await dioClient.dio.post('${ApiConstants.cctvCameras}/$cameraId/test');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<CctvRecordingModel>> getRecordingByGame(
      String gameId) async {
    final response = await dioClient.dio.get('/cctv/recordings/game/$gameId');
    return ApiResponseParser.parse<CctvRecordingModel>(
      response.data,
      (json) => CctvRecordingModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<CctvRecordingModel>> stopRecording(
      String recordingId) async {
    final response =
        await dioClient.dio.post('/cctv/recordings/$recordingId/stop');
    return ApiResponseParser.parse<CctvRecordingModel>(
      response.data,
      (json) => CctvRecordingModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<CctvRecordingModel>> extendRecording(
      String recordingId, int additionalMinutes) async {
    final response = await dioClient.dio.post(
      '/cctv/recordings/$recordingId/extend',
      data: {'additionalMinutes': additionalMinutes},
    );
    return ApiResponseParser.parse<CctvRecordingModel>(
      response.data,
      (json) => CctvRecordingModel.fromJson(json as Map<String, dynamic>),
    );
  }

  // --- Live CCTV Streaming Methods ---
  Future<ApiResponseModel<List<CctvLiveCameraOptionModel>>>
      getLiveCameras() async {
    final response = await dioClient.dio.get(ApiConstants.cctvLiveCameras);
    return ApiResponseParser.parse<List<CctvLiveCameraOptionModel>>(
      response.data,
      (json) => (json as List)
          .map((e) =>
              CctvLiveCameraOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<CctvLiveSessionModel>> createLiveSession({
    required int channel,
    String streamType = 'main',
  }) async {
    final response = await dioClient.dio.post(
      ApiConstants.cctvLiveSession,
      data: {'channel': channel, 'streamType': streamType},
    );
    return ApiResponseParser.parse<CctvLiveSessionModel>(
      response.data,
      (json) => CctvLiveSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> getLiveChannelStatus(
      int channel) async {
    final response =
        await dioClient.dio.get('${ApiConstants.cctvLiveStatus}/$channel');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> releaseLiveSession(
      String sessionId) async {
    final response = await dioClient.dio
        .post('${ApiConstants.cctvLiveSession}/$sessionId/release');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }
}
