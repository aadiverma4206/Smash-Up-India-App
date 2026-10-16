import 'package:get/get.dart';
import '../datasources/cctv_remote_datasource.dart';
import '../repositories/cctv_repository.dart';
import '../controllers/cctv_controller.dart';
import '../controllers/cctv_live_controller.dart';
import '../../../core/network/dio_client.dart';

class CctvBinding extends Bindings {
  @override
  void dependencies() {
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
