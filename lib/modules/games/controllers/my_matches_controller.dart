import 'package:get/get.dart';
import '../../player/repositories/player_repository.dart';
import '../../../data/models/game_model.dart';
import '../../notifications/services/socket_notification_service.dart';
import '../../../core/utils/app_logger.dart';

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
  }

  void _initSocketListeners() {
    try {
      if (Get.isRegistered<SocketNotificationService>()) {
        SocketNotificationService.to.onEvent('notification', (data) {
          AppLogger.info('⚡ [Socket.IO] Match notification event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:live_feed', (data) {
          AppLogger.info('⚡ [Socket.IO] Match live feed event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
        SocketNotificationService.to.onEvent('match:score_update', (data) {
          AppLogger.info('⚡ [Socket.IO] Match score update event received in MyMatchesController');
          fetchMyMatches(selectedTab.value);
        });
      }
    } catch (e) {
      AppLogger.warning('Failed to initialize socket listeners in MyMatchesController: $e');
    }
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
