import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../network/dio_client.dart';
import '../services/auth_service.dart';
import '../storage/database_service.dart';
import '../utils/app_logger.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    AppLogger.info(
        '🔔 FCM Background Message: ${message.messageId} | ${message.notification?.title}');
  } catch (e) {
    AppLogger.warning('FCM Background error: $e');
  }
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final RxnString fcmToken = RxnString();
  FirebaseMessaging? _fcm;
  FlutterLocalNotificationsPlugin? _localNotifications;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Channel used for high priority app notifications.',
    importance: Importance.high,
  );

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<NotificationService> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      AppLogger.info('🔥 Firebase initialized successfully.');

      _fcm = FirebaseMessaging.instance;

      await _initLocalNotifications();
      await _requestPermission();
      await _getFcmToken();
      _setupListeners();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      AppLogger.warning(
          'NotificationService init notice (Firebase config or Play Services pending): $e');
    }
    return this;
  }

  Future<void> _initLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications?.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            AppLogger.info('🔔 Local Notification tapped: ${response.payload}');
            _handleRouteString(response.payload!);
          }
        },
      );

      if (Platform.isAndroid) {
        await _localNotifications
            ?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }
    } catch (e) {
      AppLogger.warning('Local notifications init error: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (_fcm == null) return;
    try {
      final settings = await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info(
          '🔔 FCM Authorization Status: ${settings.authorizationStatus}');
    } catch (e) {
      AppLogger.warning('Error requesting FCM permissions: $e');
    }
  }

  Future<String?> _getFcmToken() async {
    if (_fcm == null) return null;
    try {
      final token = await _fcm!.getToken();
      if (token != null) {
        fcmToken.value = token;
        AppLogger.info('🔑 FCM Registration Token: $token');
        await registerFcmTokenWithBackend(token);
      }
      return token;
    } catch (e) {
      AppLogger.warning('Could not get FCM token: $e');
      return null;
    }
  }

  Future<void> registerFcmTokenWithBackend([String? targetToken]) async {
    final tokenToRegister = targetToken ?? fcmToken.value;
    if (tokenToRegister == null || tokenToRegister.isEmpty) return;

    try {
      if (!Get.isRegistered<AuthService>() ||
          !Get.find<AuthService>().isLoggedIn.value) {
        AppLogger.debug('User not logged in. Postponing FCM token transmit.');
        return;
      }

      if (Get.isRegistered<DioClient>()) {
        final dio = Get.find<DioClient>().dio;
        await dio.post(
          '/auth/devices/fcm-token',
          data: {
            'token': tokenToRegister,
            'platform': Platform.isAndroid ? 'ANDROID' : 'IOS',
          },
          options: Options(
            validateStatus: (status) => status != null && status < 600,
          ),
        );
        AppLogger.info('✅ FCM token sync attempted with backend.');
      }
    } catch (e) {
      AppLogger.debug(
          'FCM token registration skipped or non-critical notice: $e');
    }
  }

  Future<void> unregisterFcmTokenFromBackend() async {
    final currentToken = fcmToken.value;
    if (currentToken == null || currentToken.isEmpty) return;

    try {
      if (Get.isRegistered<DioClient>()) {
        final dio = Get.find<DioClient>().dio;
        await dio.delete(
          '/auth/devices/fcm-token',
          data: {'token': currentToken},
          options: Options(
            validateStatus: (status) => status != null && status < 600,
          ),
        );
        AppLogger.info('🚪 FCM token removal attempted with backend.');
      }
    } catch (e) {
      AppLogger.debug('FCM token unregistration notice: $e');
    }
  }

  void _setupListeners() {
    if (_fcm == null) return;
    try {
      _fcm!.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        AppLogger.info('🔄 FCM Token refreshed: $newToken');
        registerFcmTokenWithBackend(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info(
            '🔔 FCM Foreground Message Received: ${message.notification?.title}');

        _saveFcmMessageToLocalStorage(message);

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('🔔 App opened from notification tap: ${message.data}');
        _saveFcmMessageToLocalStorage(message);
        _handleNotificationClickData(message.data);
      });

      _fcm!.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          AppLogger.info(
              '🔔 Terminated App opened via notification: ${message.data}');
          _saveFcmMessageToLocalStorage(message);
          _handleNotificationClickData(message.data);
        }
      });
    } catch (e) {
      AppLogger.warning('Error setting up FCM listeners: $e');
    }
  }

  Future<void> _saveFcmMessageToLocalStorage(RemoteMessage message) async {
    try {
      if (!Get.isRegistered<AuthService>() ||
          !Get.find<AuthService>().isLoggedIn.value) {
        return;
      }
      final userId = Get.find<AuthService>().currentUser.value?.id ?? '';
      if (userId.isEmpty) return;

      final notif = message.notification;
      final notifId =
          message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';

      if (Get.isRegistered<DatabaseService>()) {
        final db = Get.find<DatabaseService>();
        await db.upsertLocalNotifications(userId, [
          {
            'id': notifId,
            'title': notif?.title ?? 'All Stars Arena',
            'body': notif?.body ?? '',
            'type': message.data['type'] ?? 'SYSTEM',
            'data': message.data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]);
      }
    } catch (e) {
      AppLogger.warning('Failed to save FCM message to local storage: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    try {
      if (_localNotifications == null) return;
      final notif = message.notification;
      if (notif == null) return;

      final payloadRoute = message.data['route'] ?? '/notifications';

      _localNotifications!.show(
        id: notif.hashCode,
        title: notif.title ?? 'All Stars Arena',
        body: notif.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payloadRoute,
      );
    } catch (e) {
      AppLogger.warning('Error showing local notification: $e');
    }
  }

  void _handleNotificationClickData(Map<String, dynamic> data) {
    if (data.containsKey('route') && data['route'] != null) {
      _handleRouteString(data['route'] as String);
    } else {
      Get.toNamed('/notifications');
    }
  }

  void _handleRouteString(String route) {
    try {
      if (route.startsWith('/')) {
        Get.toNamed(route);
      } else {
        Get.toNamed('/notifications');
      }
    } catch (e) {
      AppLogger.warning('Failed to navigate to route $route: $e');
      Get.toNamed('/notifications');
    }
  }
}
