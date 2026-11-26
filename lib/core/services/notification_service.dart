import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
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
        '🔔 FCM Background Message Received: ${message.messageId} | ${message.notification?.title}');

    // If data-only push arrives in background, trigger local notification for top bar
    if (message.notification == null && message.data.isNotEmpty) {
      final title =
          message.data['title'] ?? message.data['name'] ?? 'Smash Up India';
      final body = message.data['body'] ?? message.data['message'] ?? '';
      if (title.toString().trim().isNotEmpty ||
          body.toString().trim().isNotEmpty) {
        final localNotif = FlutterLocalNotificationsPlugin();
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);
        await localNotif.initialize(settings: initSettings);

        final notifId = (message.messageId?.hashCode ??
                    DateTime.now().millisecondsSinceEpoch)
                .abs() %
            2147483647;
        await localNotif.show(
          id: notifId,
          title: title.toString(),
          body: body.toString(),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'Channel used for high priority app notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              visibility: NotificationVisibility.public,
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: message.data['route']?.toString() ?? '/notifications',
        );
      }
    }
  } catch (e) {
    AppLogger.warning('FCM Background error: $e');
  }
}

class NotificationService extends GetxService with WidgetsBindingObserver {
  static NotificationService get to => Get.find<NotificationService>();

  final RxnString fcmToken = RxnString();
  FirebaseMessaging? _fcm;
  FlutterLocalNotificationsPlugin? _localNotifications;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Channel used for high priority app notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.debug('📱 App resumed -> Checking FCM token status...');
      registerFcmTokenWithBackend();
    }
  }

  Future<NotificationService> init() async {
    await _initLocalNotifications();
    await _requestPermission();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      AppLogger.info('🔥 Firebase initialized successfully.');

      _fcm = FirebaseMessaging.instance;

      await _getFcmToken();
      _setupListeners();
      _setupAuthListener();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      AppLogger.warning(
          'NotificationService init notice (Firebase config or Play Services pending): $e');
    }
    return this;
  }

  void _setupAuthListener() {
    if (Get.isRegistered<AuthService>()) {
      ever(Get.find<AuthService>().isLoggedIn, (bool loggedIn) {
        if (loggedIn) {
          AppLogger.info(
              '🔑 User logged in -> Syncing FCM token with backend.');
          registerFcmTokenWithBackend();
        }
      });
      if (Get.find<AuthService>().isLoggedIn.value) {
        registerFcmTokenWithBackend();
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
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
    try {
      if (Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (_) {}

        final androidPlugin =
            _localNotifications?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      if (_fcm != null) {
        final settings = await _fcm!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: true,
        );
        await _fcm!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.info(
            '🔔 FCM Authorization Status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      AppLogger.warning('Error requesting FCM permissions: $e');
    }
  }

  Future<String?> _getFcmToken() async {
    if (_fcm == null) return null;
    try {
      final token = await _fcm!.getToken();
      if (token != null && token.isNotEmpty) {
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
    var tokenToRegister = targetToken ?? fcmToken.value;
    if ((tokenToRegister == null || tokenToRegister.isEmpty) && _fcm != null) {
      try {
        tokenToRegister = await _fcm!.getToken();
        if (tokenToRegister != null && tokenToRegister.isNotEmpty) {
          fcmToken.value = tokenToRegister;
        }
      } catch (e) {
        AppLogger.warning(
            'Failed to fetch FCM token on registration retry: $e');
      }
    }

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

  void triggerLocalTestAlert() {
    showNotificationBarAlert(
      title: '🔔 Test Notification Alert',
      body: 'This is a test notification bar alert from Smash Up India!',
      payloadRoute: '/notifications',
    );
  }

  Future<void> testBackendNotificationPush() async {
    try {
      if (!Get.isRegistered<AuthService>() ||
          !Get.find<AuthService>().isLoggedIn.value) {
        return;
      }
      final userId = Get.find<AuthService>().currentUser.value?.id;
      if (userId == null || userId.isEmpty) return;

      if (Get.isRegistered<DioClient>()) {
        final dio = Get.find<DioClient>().dio;
        await dio.post(
          '/realtime/notifications/send',
          data: {
            'userId': userId,
            'title': '⚡ Live Push Test',
            'message': 'Testing real-time notification push to system bar!',
            'type': 'INFO',
          },
          options: Options(
            validateStatus: (status) => status != null && status < 600,
          ),
        );
        AppLogger.info('✅ Backend test push notification triggered.');
      }
    } catch (e) {
      AppLogger.warning('Failed to trigger test backend push: $e');
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
        _showLocalNotification(message);
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
            'title': notif?.title ?? message.data['title'] ?? 'Smash Up India',
            'body': notif?.body ??
                message.data['body'] ??
                message.data['message'] ??
                '',
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

  void showNotificationBarAlert({
    required String title,
    required String body,
    String? payloadRoute,
    int? id,
  }) {
    try {
      if (_localNotifications == null) return;
      if (title.isEmpty && body.isEmpty) return;

      final notificationId =
          id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final route = payloadRoute ?? '/notifications';

      _localNotifications!.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
      AppLogger.info('🔔 Top Notification Bar Alert shown: "$title"');
    } catch (e) {
      AppLogger.warning('Error showing top notification bar alert: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    try {
      final notif = message.notification;
      final title = notif?.title ??
          message.data['title'] ??
          message.data['name'] ??
          'Smash Up India';
      final body =
          notif?.body ?? message.data['body'] ?? message.data['message'] ?? '';

      final payloadRoute = message.data['route'] ?? '/notifications';
      final notifId = notif?.hashCode ?? message.messageId.hashCode;

      showNotificationBarAlert(
        title: title,
        body: body,
        payloadRoute: payloadRoute,
        id: notifId,
      );
    } catch (e) {
      AppLogger.warning('Error in _showLocalNotification: $e');
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
