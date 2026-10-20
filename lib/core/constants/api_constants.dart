import '../config/env_config.dart';

class ApiConstants {
  static String get razorpayKey => EnvConfig.razorpayKeyId.isNotEmpty
      ? EnvConfig.razorpayKeyId
      : 'rzp_test_Sb44esbmpGlzBd';

  static const String sendRegisterOtp = '/auth/register/send-otp';
  static const String verifyRegisterOtp = '/auth/register/verify';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotSendOtp = '/auth/forgot/send-otp';
  static const String forgotVerifyOtp = '/auth/forgot/verify';
  static const String resetPassword = '/auth/reset-password';

  static const String playerProfile = '/player/profile';
  static const String playerStats = '/player/stats';
  static const String playerHistory = '/player/history';

  static const String wallet = '/wallet';
  static const String walletPin = '/wallet/pin';
  static const String walletPinChange = '/wallet/pin/change';
  static const String walletPinVerify = '/wallet/pin/verify';
  static const String walletTopupOrder = '/wallet/topup/order';
  static const String walletTopupVerify = '/wallet/topup/verify';
  static const String walletTransactions = '/wallet/transactions';

  static const String games = '/games';
  static const String liveMatches = '/matches/live';

  static const String courts = '/courts';
  static const String bookings = '/bookings';

  static const String cctvCameras = '/cctv/cameras';
  static const String cctvPlayback = '/cctv/playback';
  static const String cctvLiveCameras = '/cctv/live/cameras';
  static const String cctvLiveSession = '/cctv/live/session';
  static const String cctvLiveStatus = '/cctv/live/status';
}
