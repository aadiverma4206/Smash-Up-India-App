import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    AppLogger.info('🔔 FCM Background Message: ${message.messageId} | ${message.notification?.title}');
  } catch (e) {
    AppLogger.warning('FCM Background error: $e');
  }
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final RxnString fcmToken = RxnString();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<NotificationService> init() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('🔥 Firebase initialized successfully.');

      await _requestPermission();
      await _getFcmToken();
      _setupForegroundAndOpenedAppListeners();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      AppLogger.warning('NotificationService init notice (Firebase config pending): $e');
    }
    return this;
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info('🔔 FCM Authorization Status: ${settings.authorizationStatus}');
    } catch (e) {
      AppLogger.warning('Error requesting FCM permissions: $e');
    }
  }

  Future<String?> _getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        fcmToken.value = token;
        AppLogger.info('🔑 FCM Registration Token: $token');
      }
      return token;
    } catch (e) {
      AppLogger.warning('Could not get FCM token: $e');
      return null;
    }
  }

  void _setupForegroundAndOpenedAppListeners() {
    // 1. Foreground Message Received
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('🔔 FCM Foreground Message Received: ${message.notification?.title}');
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    });

    // 2. App Opened From Background State via Notification Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('🔔 App opened from notification tap: ${message.data}');
      _handleNotificationClickData(message.data);
    });

    // 3. App Opened From Terminated State via Notification Tap
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.info('🔔 Terminated App opened via notification: ${message.data}');
        _handleNotificationClickData(message.data);
      }
    });
  }

  void _handleNotificationClickData(Map<String, dynamic> data) {
    if (data.containsKey('route')) {
      final route = data['route'] as String;
      Get.toNamed(route);
    } else {
      Get.toNamed('/manager/notifications');
    }
  }
}
