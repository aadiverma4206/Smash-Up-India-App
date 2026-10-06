import '../datasources/auth_remote_datasource.dart';
import '../../../data/models/login_request_model.dart';
import '../../../data/models/login_response_model.dart';
import '../../../data/models/register_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/session_model.dart';
import '../../../core/errors/app_exception.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepository({required this.remoteDataSource});

  Future<void> sendRegisterOtp(RegisterSendOtpRequestModel request) async {
    await remoteDataSource.sendRegisterOtp(request);
  }

  Future<String> verifyRegisterOtp(
      RegisterVerifyOtpRequestModel request) async {
    final response = await remoteDataSource.verifyRegisterOtp(request);
    return response.data?['verificationToken'] as String? ?? '';
  }

  Future<LoginResponseModel> registerPlayer(
      RegisterPlayerRequestModel request) async {
    final response = await remoteDataSource.registerPlayer(request);
    if (response.data == null) {
      throw AppException(
          'Registration succeeded but user details were missing.');
    }
    return response.data!;
  }

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await remoteDataSource.login(request);
    if (response.data == null) {
      throw AppException('Login failed. Invalid response from server.');
    }
    return response.data!;
  }

  Future<UserModel> getMe() async {
    final response = await remoteDataSource.getMe();
    if (response.data == null) {
      throw AppException('User profile not found.');
    }
    return response.data!;
  }

  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  Future<void> logoutAll() async {
    await remoteDataSource.logoutAll();
  }

  Future<List<SessionModel>> getSessions() async {
    final response = await remoteDataSource.getSessions();
    return response.data ?? [];
  }

  Future<void> revokeSession(String sessionId) async {
    await remoteDataSource.revokeSession(sessionId);
  }

  Future<void> forgotSendOtp(String identifier) async {
    await remoteDataSource.forgotSendOtp(identifier);
  }

  Future<String> forgotVerifyOtp(String identifier, String otp) async {
    final response = await remoteDataSource.forgotVerifyOtp(identifier, otp);
    return response.data?['resetToken'] as String? ?? '';
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await remoteDataSource.resetPassword(resetToken, newPassword);
  }
}
