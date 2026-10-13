import 'package:get/get.dart';
import '../datasources/admin_remote_datasource.dart';
import '../repositories/admin_repository.dart';
import '../controllers/admin_controller.dart';
import '../../manager/datasources/manager_remote_datasource.dart';
import '../../manager/repositories/manager_repository.dart';
import '../../manager/controllers/manager_games_controller.dart';
import '../../cctv/datasources/cctv_remote_datasource.dart';
import '../../cctv/repositories/cctv_repository.dart';
import '../../cctv/controllers/cctv_controller.dart';
import '../../../core/network/dio_client.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRemoteDataSource>(
      () => AdminRemoteDataSource(dioClient: Get.find<DioClient>()),
    );
    Get.lazyPut<AdminRepository>(
      () =>
          AdminRepository(remoteDataSource: Get.find<AdminRemoteDataSource>()),
    );
    Get.lazyPut<AdminController>(
      () => AdminController(),
    );

    // Manager & History dependencies for Admin Dashboard History Tab
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
    if (!Get.isRegistered<ManagerGamesController>()) {
      Get.lazyPut<ManagerGamesController>(
        () => ManagerGamesController(),
        fenix: true,
      );
    }

    // CCTV dependencies
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
  }
}
