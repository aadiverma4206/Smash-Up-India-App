import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      AppLogger.warning('Initial connectivity check warning: $e');
    }

    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final previouslyConnected = isConnected.value;
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      isConnected.value = false;
      AppLogger.info('📶 Network status: OFFLINE');
    } else {
      isConnected.value = true;
      AppLogger.info('📶 Network status: ONLINE');
      if (!previouslyConnected) {
        AppLogger.info(
            '⚡ Connection restored: Triggering online synchronization...');
      }
    }
  }
}
