import 'package:get/get.dart';
import '../datasources/auth_remote_datasource.dart';
import '../repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../app/bindings/initial_binding.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DioClient>()) {
      InitialBinding().dependencies();
    }
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(dioClient: Get.find<DioClient>()),
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(remoteDataSource: Get.find<AuthRemoteDataSource>()),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}
