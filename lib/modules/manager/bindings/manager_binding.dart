import 'package:get/get.dart';
import '../datasources/manager_remote_datasource.dart';
import 'package:all_stars_arena/modules/manager/repositories/manager_repository.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../controllers/manager_games_controller.dart';
import '../../cctv/datasources/cctv_remote_datasource.dart';
import '../../cctv/repositories/cctv_repository.dart';
import '../../cctv/controllers/cctv_controller.dart';
import '../../cctv/controllers/cctv_live_controller.dart';
import '../../games/datasources/games_remote_datasource.dart';
import '../../games/repositories/games_repository.dart';
import '../../player/datasources/player_remote_datasource.dart';
import '../../player/repositories/player_repository.dart';
import '../../player/controllers/notifications_controller.dart';
import '../../../core/network/dio_client.dart';

class ManagerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GamesRemoteDataSource>()) {
      Get.lazyPut<GamesRemoteDataSource>(
        () => GamesRemoteDataSource(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GamesRepository>()) {
      Get.lazyPut<GamesRepository>(
        () => GamesRepository(
            remoteDataSource: Get.find<GamesRemoteDataSource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ManagerRemoteDataSource>()) {
      Get.lazyPut<ManagerRemoteDataSource>(
        () => ManagerRemoteDataSource(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ManagerRepository>()) {
      Get.lazyPut<ManagerRepository>(
        () => ManagerRepository(
            remoteDataSource: Get.find<ManagerRemoteDataSource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PlayerRemoteDataSource>()) {
      Get.lazyPut<PlayerRemoteDataSource>(
        () => PlayerRemoteDataSource(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<PlayerRepository>()) {
      Get.lazyPut<PlayerRepository>(
        () => PlayerRepository(
            remoteDataSource: Get.find<PlayerRemoteDataSource>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<NotificationsController>()) {
      Get.lazyPut<NotificationsController>(
        () => NotificationsController(),
        fenix: true,
      );
    }

    Get.lazyPut<ManagerDashboardController>(
      () => ManagerDashboardController(),
      fenix: true,
    );
    Get.lazyPut<ManagerGamesController>(
      () => ManagerGamesController(),
      fenix: true,
    );

    if (!Get.isRegistered<CctvRemoteDataSource>()) {
      Get.lazyPut<CctvRemoteDataSource>(
        () => CctvRemoteDataSource(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CctvRepository>()) {
      Get.lazyPut<CctvRepository>(
        () =>
            CctvRepository(remoteDataSource: Get.find<CctvRemoteDataSource>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CctvController>()) {
      Get.lazyPut<CctvController>(
        () => CctvController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CctvLiveController>()) {
      Get.lazyPut<CctvLiveController>(
        () => CctvLiveController(),
        fenix: true,
      );
    }
  }
}
