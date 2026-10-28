import 'package:get/get.dart';
import '../../player/repositories/player_repository.dart';
import '../../../data/models/game_model.dart';
import '../../notifications/services/socket_notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/services/connectivity_service.dart';

class MyMatchesController extends GetxController {
  final PlayerRepository repository = Get.find<PlayerRepository>();

  final RxString selectedTab = 'UPCOMING'.obs;
  final RxList<GameModel> matchesList = <GameModel>[].obs;
  final RxBool isLoading = false.obs;

  final tabs = ['UPCOMING', 'ONGOING'];

  @override
  void onInit() {
    super.onInit();
    fetchMyMatches(selectedTab.value);
    _initSocketListeners();

    if (Get.isRegistered<ConnectivityService>()) {
      ConnectivityService.to.isConnected.listen((connected) {
        if (connected) {
          AppLogger.info(
              '⚡ Connection restored: Auto-refreshing player matches');
          fetchMyMatches(selectedTab.value);
        }
      });
    }
  }

  void _initSocketListeners() {
    try {
      if (Get.isRegistered<SocketNotificationService>()) {
        SocketNotificationService.to.onEvent('notification', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match notification event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:live_feed', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match live feed event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:score_update', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match score update event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:cancelled', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match cancelled event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:approved', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match approved event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
      }
    } catch (e) {
      AppLogger.warning(
          'Failed to initialize socket listeners in MyMatchesController: $e');
    }
  }

  List<GameModel> get filteredMatches {
    final now = DateTime.now();
    return matchesList.where((m) {
      final statusUpper = m.status.toUpperCase();
      // Cancelled, rejected, or completed matches must NEVER appear in My Matches upcoming/ongoing tabs!
      if (statusUpper == 'CANCELLED' ||
          statusUpper == 'COMPLETED' ||
          statusUpper == 'FINISHED' ||
          statusUpper == 'REJECTED') {
        return false;
      }

      final startDt = AppDateUtils.parseMatchDateTime(m.matchDate, m.startTime);
      final endDt = AppDateUtils.parseMatchDateTime(m.matchDate, m.endTime);

      if (selectedTab.value == 'UPCOMING') {
        if (endDt != null && endDt.isBefore(now)) return false; // Past match!
        if (startDt != null && startDt.isAfter(now))
          return true; // Future match!
        return statusUpper != 'ONGOING';
      } else if (selectedTab.value == 'ONGOING') {
        if (statusUpper == 'ONGOING') return true;
        if (startDt != null &&
            startDt.isBefore(now) &&
            endDt != null &&
            endDt.isAfter(now)) {
          return true;
        }
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> fetchMyMatches(String tab) async {
    selectedTab.value = tab;
    isLoading.value = true;
    try {
      final list = await repository.getMyMatches(tab: tab);
      matchesList.value = list;
    } catch (e) {
      matchesList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
