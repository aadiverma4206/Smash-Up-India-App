import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../../core/config/env_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/notification_model.dart';
import '../../player/controllers/notifications_controller.dart';

class SocketNotificationService extends GetxService {
  static SocketNotificationService get to =>
      Get.find<SocketNotificationService>();

  socket_io.Socket? _socket;
  final RxBool isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    connectSocket();
  }

  Future<void> connectSocket() async {
    try {
      if (!Get.isRegistered<AuthService>() ||
          !Get.find<AuthService>().isLoggedIn.value) {
        AppLogger.debug('Socket connect skipped: User not authenticated.');
        return;
      }

      final token = await Get.find<SecureStorageService>().getAccessToken();
      final baseUrl = EnvConfig.baseUrl.replaceAll('/api/v1', '');

      if (baseUrl.isEmpty) {
        AppLogger.warning('Socket connect skipped: BASE_URL is empty.');
        return;
      }

      _socket = socket_io.io(
        baseUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        isConnected.value = true;
        AppLogger.info('⚡ [Socket.IO] Connected successfully.');

        final userId = AuthService.to.currentUser.value?.id;
        if (userId != null && userId.isNotEmpty) {
          _socket?.emit('join:user', userId);
          AppLogger.info('⚡ [Socket.IO] Joined user room: user:$userId');
        }
      });

      _socket?.on('notification', (data) {
        AppLogger.info('🔔 [Socket.IO] Real-time notification received: $data');
        _handleIncomingSocketNotification(data);
      });

      _socket?.onDisconnect((_) {
        isConnected.value = false;
        AppLogger.info('⚡ [Socket.IO] Disconnected.');
      });

      _socket?.onError((err) {
        AppLogger.warning('⚡ [Socket.IO] Error: $err');
      });
    } catch (e) {
      AppLogger.warning('Failed to initialize Socket.IO client: $e');
    }
  }

  void _handleIncomingSocketNotification(dynamic rawData) {
    try {
      if (rawData is! Map<String, dynamic>) return;

      final model = NotificationModel(
        id: rawData['id'] ?? 'sock_${DateTime.now().millisecondsSinceEpoch}',
        title: rawData['title'] ?? 'New Notification',
        body: rawData['message'] ?? rawData['body'] ?? '',
        type: rawData['type'] ?? 'SYSTEM',
        data: rawData['data'] is Map<String, dynamic> ? rawData['data'] : null,
        isRead: false,
        createdAt: rawData['timestamp'] ?? DateTime.now().toIso8601String(),
      );

      if (Get.isRegistered<NotificationsController>()) {
        final controller = Get.find<NotificationsController>();
        final exists = controller.notifications.any((n) => n.id == model.id);
        if (!exists) {
          controller.notifications.insert(0, model);
        }
      }

      // TRIGGER TOP NOTIFICATION BAR ALERT
      if (Get.isRegistered<NotificationService>()) {
        NotificationService.to.showNotificationBarAlert(
          title: model.title,
          body: model.body,
          payloadRoute: model.data?['route']?.toString() ?? '/notifications',
          id: model.id.hashCode.abs(),
        );
      }
    } catch (e) {
      AppLogger.warning('Error handling socket notification payload: $e');
    }
  }

  void onEvent(String eventName, Function(dynamic) handler) {
    try {
      _socket?.on(eventName, (data) => handler(data));
    } catch (e) {
      AppLogger.warning('Error registering socket event $eventName: $e');
    }
  }

  void offEvent(String eventName) {
    try {
      _socket?.off(eventName);
    } catch (e) {
      AppLogger.warning('Error unregistering socket event $eventName: $e');
    }
  }

  void disconnectSocket() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      isConnected.value = false;
      AppLogger.info('⚡ [Socket.IO] Socket closed and disposed.');
    } catch (e) {
      AppLogger.warning('Error disconnecting Socket.IO: $e');
    }
  }

  @override
  void onClose() {
    disconnectSocket();
    super.onClose();
  }
}
