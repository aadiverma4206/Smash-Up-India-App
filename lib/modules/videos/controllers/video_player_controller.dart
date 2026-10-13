import 'package:get/get.dart';

class VideoPlayerController extends GetxController {
  final RxString playbackUrl = ''.obs;
  final RxString title = 'Match CCTV Video Playback'.obs;
  final RxList<Map<String, dynamic>> cameras = <Map<String, dynamic>>[].obs;
  final RxInt selectedCameraIndex = 0.obs;
  final RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      playbackUrl.value =
          (args['videoUrl'] ?? args['playbackUrl'] ?? args['url'] ?? '')
              .toString();
      title.value = (args['title'] ?? 'Match CCTV Video Playback').toString();
      if (args['cameras'] is List) {
        cameras.value = (args['cameras'] as List).cast<Map<String, dynamic>>();
      }
      if (args['initialIndex'] is int && (args['initialIndex'] as int) >= 0) {
        selectedCameraIndex.value = args['initialIndex'] as int;
      }
    } else if (args is String) {
      playbackUrl.value = args;
    }
    if (playbackUrl.value.isEmpty) {
      playbackUrl.value =
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    }
  }

  void switchCamera(int index) {
    if (index >= 0 && index < cameras.length) {
      selectedCameraIndex.value = index;
      final cam = cameras[index];
      final url = (cam['playbackUrl'] ?? cam['videoUrl'] ?? cam['url'] ?? '')
          .toString();
      if (url.isNotEmpty) {
        playbackUrl.value = url;
      }
      final camName =
          (cam['cameraName'] ?? cam['name'] ?? 'Camera ${index + 1}')
              .toString();
      title.value = 'Match CCTV - $camName';
    }
  }

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
  }
}
