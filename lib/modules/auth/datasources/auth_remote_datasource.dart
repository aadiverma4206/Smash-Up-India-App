import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/login_request_model.dart';
import '../../../data/models/login_response_model.dart';
import '../../../data/models/register_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/session_model.dart';

class AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<Map<String, dynamic>>> sendRegisterOtp(
      RegisterSendOtpRequestModel request) async {
    final response = await dioClient.dio.post(
      ApiConstants.sendRegisterOtp,
      data: request.toJson(),
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> verifyRegisterOtp(
      RegisterVerifyOtpRequestModel request) async {
    final response = await dioClient.dio.post(
      ApiConstants.verifyRegisterOtp,
      data: request.toJson(),
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<LoginResponseModel>> registerPlayer(
      RegisterPlayerRequestModel request) async {
    final response = await dioClient.dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    return ApiResponseParser.parse<LoginResponseModel>(
      response.data,
      (json) => LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<LoginResponseModel>> login(
      LoginRequestModel request) async {
    final response = await dioClient.dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    return ApiResponseParser.parse<LoginResponseModel>(
      response.data,
      (json) => LoginResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<UserModel>> getMe() async {
    final response = await dioClient.dio.get(ApiConstants.me);
    return ApiResponseParser.parse<UserModel>(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await dioClient.dio.post(ApiConstants.logout);
  }

  Future<void> logoutAll() async {
    await dioClient.dio.post('/auth/logout-all');
  }

  Future<ApiResponseModel<List<SessionModel>>> getSessions() async {
    final response = await dioClient.dio.get('/auth/sessions');
    return ApiResponseParser.parse<List<SessionModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> revokeSession(String sessionId) async {
    await dioClient.dio.delete('/auth/sessions/$sessionId');
  }

  Future<ApiResponseModel<Map<String, dynamic>>> forgotSendOtp(
      String identifier) async {
    final response = await dioClient.dio.post(
      ApiConstants.forgotSendOtp,
      data: {'identifier': identifier},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> forgotVerifyOtp(
      String identifier, String otp) async {
    final response = await dioClient.dio.post(
      ApiConstants.forgotVerifyOtp,
      data: {'identifier': identifier, 'otp': otp},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> resetPassword(
      String resetToken, String newPassword) async {
    final response = await dioClient.dio.post(
      ApiConstants.resetPassword,
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }
}
