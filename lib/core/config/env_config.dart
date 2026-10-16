import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'ALL STARS ARENA';
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.1.21:5000/api/v1';
  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static int get connectTimeout =>
      int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '60000');
  static int get receiveTimeout =>
      int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '60000');

  static Future<void> init({String envFile = '.env.dev'}) async {
    await dotenv.load(fileName: envFile);
  }
}
