import 'package:get/get.dart';
import '../../player/bindings/player_binding.dart';
import '../controllers/create_game_controller.dart';
import '../controllers/games_controller.dart';
import '../controllers/game_details_controller.dart';
import '../controllers/my_matches_controller.dart';

class CreateGameBinding extends Bindings {
  @override
  void dependencies() {
    PlayerBinding().dependencies();

    if (!Get.isRegistered<CreateGameController>()) {
      Get.lazyPut<CreateGameController>(
        () => CreateGameController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GamesController>()) {
      Get.lazyPut<GamesController>(
        () => GamesController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GameDetailsController>()) {
      Get.lazyPut<GameDetailsController>(
        () => GameDetailsController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<MyMatchesController>()) {
      Get.lazyPut<MyMatchesController>(
        () => MyMatchesController(),
        fenix: true,
      );
    }
  }
}
