import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/config/env_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';

class VideoPlayerController extends GetxController {
  vp.VideoPlayerController? videoPlayerController;

  final RxString playbackUrl = ''.obs;
  final RxString resolvedUrl = ''.obs;
  final RxString title = 'Match CCTV Video Playback'.obs;
  final RxList<Map<String, dynamic>> cameras = <Map<String, dynamic>>[].obs;
  final RxInt selectedCameraIndex = 0.obs;

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxBool isControlsVisible = true.obs;
  final RxBool isFullScreen = false.obs;

  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString localFilePath = ''.obs;
  final RxBool isDownloaded = false.obs;

  Timer? _controlsTimer;

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

    if (playbackUrl.value.isNotEmpty) {
      _initPlayer(playbackUrl.value);
    } else {
      hasError.value = true;
      errorMessage.value = 'No video URL was provided for playback.';
    }
  }

  String resolveAbsoluteUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    final base = EnvConfig.baseUrl
        .replaceAll(RegExp(r'/api(/v1)?/?$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$base$cleanPath';
  }

  Future<void> _initPlayer(String url) async {
    isInitialized.value = false;
    hasError.value = false;
    errorMessage.value = '';
    isBuffering.value = true;

    if (url.trim().isEmpty ||
        url.contains('BigBuckBunny') ||
        url.contains('commondatastorage.googleapis.com')) {
      hasError.value = true;
      isBuffering.value = false;
      errorMessage.value =
          'No recorded video footage is available for this match.';
      return;
    }

    final filename = url.split('/').last.split('?').first;
    if (filename.isNotEmpty) {
      final localPath = await _getLocalVideoPath(filename);
      if (await File(localPath).exists()) {
        localFilePath.value = localPath;
        isDownloaded.value = true;
      }
    }

    try {
      await videoPlayerController?.dispose();
      videoPlayerController = null;

      if (localFilePath.value.isNotEmpty &&
          await File(localFilePath.value).exists()) {
        AppLogger.info('📼 Playing offline video: ${localFilePath.value}');
        videoPlayerController =
            vp.VideoPlayerController.file(File(localFilePath.value));
      } else {
        final fullUrl = resolveAbsoluteUrl(url);
        resolvedUrl.value = fullUrl;
        AppLogger.info('🌐 Streaming video from URL: $fullUrl');

        Map<String, String>? headers;
        if (Get.isRegistered<SecureStorageService>()) {
          final token = await Get.find<SecureStorageService>().getAccessToken();
          if (token != null && token.isNotEmpty) {
            headers = {'Authorization': 'Bearer $token'};
          }
        }

        videoPlayerController = vp.VideoPlayerController.networkUrl(
          Uri.parse(fullUrl),
          httpHeaders: headers ?? const {},
        );
      }

      await videoPlayerController!.initialize();
      totalDuration.value = videoPlayerController!.value.duration;
      isInitialized.value = true;
      isBuffering.value = false;

      videoPlayerController!.addListener(_videoListener);

      await videoPlayerController!.play();
      isPlaying.value = true;
      _startControlsHideTimer();
    } catch (e) {
      AppLogger.error('❌ Video Player initialization failed: $e');
      hasError.value = true;
      isBuffering.value = false;
      errorMessage.value =
          'Failed to load video stream. Please check network connection.\n$e';
    }
  }

  void _videoListener() {
    if (videoPlayerController == null) return;
    final value = videoPlayerController!.value;
    isPlaying.value = value.isPlaying;
    isBuffering.value = value.isBuffering;
    currentPosition.value = value.position;
    totalDuration.value = value.duration;

    if (value.hasError) {
      hasError.value = true;
      errorMessage.value =
          value.errorDescription ?? 'An error occurred during video playback.';
    }
  }

  void togglePlay() {
    if (videoPlayerController == null || !isInitialized.value) return;
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
      isPlaying.value = false;
      _controlsTimer?.cancel();
      isControlsVisible.value = true;
    } else {
      videoPlayerController!.play();
      isPlaying.value = true;
      _startControlsHideTimer();
    }
  }

  void seekTo(Duration position) {
    if (videoPlayerController == null || !isInitialized.value) return;
    videoPlayerController!.seekTo(position);
    _startControlsHideTimer();
  }

  void seekForward10() {
    if (videoPlayerController == null || !isInitialized.value) return;
    final target = currentPosition.value + const Duration(seconds: 10);
    final clamped = target > totalDuration.value ? totalDuration.value : target;
    seekTo(clamped);
  }

  void seekBackward10() {
    if (videoPlayerController == null || !isInitialized.value) return;
    final target = currentPosition.value - const Duration(seconds: 10);
    final clamped = target < Duration.zero ? Duration.zero : target;
    seekTo(clamped);
  }

  void toggleControls() {
    isControlsVisible.value = !isControlsVisible.value;
    if (isControlsVisible.value && isPlaying.value) {
      _startControlsHideTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void toggleFullScreen() {
    isFullScreen.value = !isFullScreen.value;
    if (isFullScreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _startControlsHideTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (isPlaying.value) {
        isControlsVisible.value = false;
      }
    });
  }

  void switchCamera(int index) {
    if (index >= 0 && index < cameras.length) {
      selectedCameraIndex.value = index;
      final cam = cameras[index];
      final url = (cam['playbackUrl'] ?? cam['videoUrl'] ?? cam['url'] ?? '')
          .toString();
      if (url.isNotEmpty) {
        playbackUrl.value = url;
        localFilePath.value = '';
        isDownloaded.value = false;
        _initPlayer(url);
      }
      final camName =
          (cam['cameraName'] ?? cam['name'] ?? 'Camera ${index + 1}')
              .toString();
      title.value = 'Match CCTV - $camName';
    }
  }

  Future<String> _getLocalVideoPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${dir.path}/recorded_matches');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    return '${videosDir.path}/$filename';
  }

  Future<void> downloadVideo() async {
    if (isDownloading.value || isDownloaded.value) return;

    final url = resolvedUrl.value.isNotEmpty
        ? resolvedUrl.value
        : resolveAbsoluteUrl(playbackUrl.value);
    if (url.isEmpty) return;

    final filename = url.split('/').last.split('?').first;
    final savePath = await _getLocalVideoPath(filename);

    isDownloading.value = true;
    downloadProgress.value = 0.0;

    try {
      final dio = Dio();
      final downloadUrl =
          url.contains('?') ? '$url&download=1' : '$url?download=1';

      Options? options;
      if (Get.isRegistered<SecureStorageService>()) {
        final token = await Get.find<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          options = Options(headers: {'Authorization': 'Bearer $token'});
        }
      }

      await dio.download(
        downloadUrl,
        savePath,
        options: options,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
      );

      isDownloaded.value = true;
      localFilePath.value = savePath;
      Get.snackbar(
        'Video Downloaded',
        'Match recording saved offline for fast playback.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      AppLogger.error('Download video failed: $e');
      Get.snackbar(
        'Download Failed',
        'Could not save video to device: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  void retry() {
    if (playbackUrl.value.isNotEmpty) {
      _initPlayer(playbackUrl.value);
    }
  }

  @override
  void onClose() {
    _controlsTimer?.cancel();
    videoPlayerController?.removeListener(_videoListener);
    videoPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }
}
