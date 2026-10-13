import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../repositories/cctv_repository.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/utils/app_logger.dart';

/// Controller for dynamic live CCTV streaming view.
///
/// Fetches camera channels dynamically from host credentials / backend database.
/// Connects directly to camera RTSP stream credentials with zero FFmpeg dependency.
class CctvLiveController extends GetxController {
  final CctvRepository repository = Get.find<CctvRepository>();

  final RxList<CctvLiveCameraOptionModel> cameraOptions =
      <CctvLiveCameraOptionModel>[].obs;
  final RxInt selectedChannel = 1.obs;

  // Default to 'sub' stream (lower bitrate, better for mobile)
  final RxString streamType = 'sub'.obs;

  final Rxn<CctvLiveSessionModel> currentSession = Rxn<CctvLiveSessionModel>();
  final RxMap<int, String> channelStatuses = <int, String>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isPlayerInitializing = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxBool isMuted = true.obs;
  final RxString errorMessage = ''.obs;

  VideoPlayerController? videoPlayerController;

  @override
  void onInit() {
    super.onInit();
    int initialChannel = 1;
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args['channel'] != null) {
      initialChannel = (args['channel'] as num).toInt();
    } else if (args is int) {
      initialChannel = args;
    }
    _loadLiveCamerasAndConnect(initialChannel);
  }

  @override
  void onClose() {
    _disposePlayer();
    _releaseCurrentSession();
    super.onClose();
  }

  Future<void> _disposePlayer() async {
    if (videoPlayerController != null) {
      try {
        videoPlayerController!.removeListener(_videoListener);
        await videoPlayerController!.pause();
        await videoPlayerController!.dispose();
      } catch (e) {
        AppLogger.warning('Error disposing VideoPlayer: $e');
      }
      videoPlayerController = null;
    }
  }

  Future<void> _releaseCurrentSession() async {
    if (currentSession.value != null) {
      final sessId = currentSession.value!.sessionId;
      currentSession.value = null;
      await repository.releaseLiveSession(sessId);
    }
  }

  Future<void> _loadLiveCamerasAndConnect(int initialChannel) async {
    isLoading.value = true;
    try {
      final list = await repository.getLiveCameras();
      if (list.isNotEmpty) {
        cameraOptions.assignAll(list);
        for (var c in list) {
          channelStatuses[c.channel] =
              c.status == 'ONLINE' ? 'Connecting' : 'Offline';
        }
      } else {
        _populateDefaultChannels();
      }
    } catch (e) {
      AppLogger.warning('Failed to load live camera list: $e');
      _populateDefaultChannels();
    } finally {
      isLoading.value = false;
      final targetChan = cameraOptions.any((c) => c.channel == initialChannel)
          ? initialChannel
          : (cameraOptions.isNotEmpty ? cameraOptions.first.channel : 1);
      selectCamera(targetChan);
    }
  }

  void _populateDefaultChannels() {
    cameraOptions.assignAll([
      CctvLiveCameraOptionModel(
          id: 'cam_1',
          channel: 1,
          name: 'Camera 1 (Main Pitch)',
          courtName: 'Court 1'),
      CctvLiveCameraOptionModel(
          id: 'cam_2',
          channel: 2,
          name: 'Camera 2 (Side Pitch)',
          courtName: 'Court 2'),
      CctvLiveCameraOptionModel(
          id: 'cam_3',
          channel: 3,
          name: 'Camera 3 (Goal View A)',
          courtName: 'Court 1'),
      CctvLiveCameraOptionModel(
          id: 'cam_4',
          channel: 4,
          name: 'Camera 4 (Goal View B)',
          courtName: 'Court 2'),
    ]);
    for (var c in cameraOptions) {
      channelStatuses[c.channel] = 'Connecting';
    }
  }

  Future<void> selectCamera(int channel) async {
    if (channel < 1) return;
    selectedChannel.value = channel;
    channelStatuses[channel] = 'Connecting';
    errorMessage.value = '';

    await _disposePlayer();
    await _releaseCurrentSession();

    isPlayerInitializing.value = true;
    isPlaying.value = false;

    try {
      final session = await repository.createLiveSession(
        channel: channel,
        streamType: streamType.value,
      );

      currentSession.value = session;

      if (session.status == 'OFFLINE') {
        channelStatuses[channel] = 'Offline';
        errorMessage.value =
            'DVR Host 192.168.1.2:554 is unreachable.\n'
            '• Connect mobile device to local court Wi-Fi (192.168.1.x).';
        isPlayerInitializing.value = false;
        return;
      }

      final streamUrl = session.playbackUrl;

      if (streamUrl.isEmpty) {
        channelStatuses[channel] = 'Offline';
        errorMessage.value =
            'Network unreachable: DVR IP 192.168.1.2:554 cannot be reached directly from this device.';
        isPlayerInitializing.value = false;
        return;
      }

      AppLogger.info(
          'Connecting VideoPlayer to Channel $channel (${streamType.value.toUpperCase()}): $streamUrl');

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        httpHeaders: {
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      );

      videoPlayerController = controller;
      controller.addListener(_videoListener);

      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Stream initialization timed out. The camera stream at 192.168.1.2:554 is not responding.');
        },
      );

      await controller.setVolume(isMuted.value ? 0.0 : 1.0);
      await controller.play();

      isPlaying.value = true;
      channelStatuses[channel] = 'Live';
      errorMessage.value = '';
      isPlayerInitializing.value = false;
    } catch (e) {
      final errStr = e.toString();
      AppLogger.error('Failed to initialize live camera session: $e');

      channelStatuses[channel] = 'Connection failed';
      if (errStr.contains('ExoPlaybackSource') ||
          errStr.contains('Source error') ||
          errStr.contains('timeout')) {
        errorMessage.value =
            'Network unreachable: 192.168.1.2:554 cannot be reached from this device.\n'
            'Please connect device to court Wi-Fi (192.168.1.x).';
      } else {
        errorMessage.value =
            'Connection failed: ${errStr.replaceAll('Exception: ', '').replaceAll('PlatformException(', '').replaceAll(')', '')}';
      }
      isPlayerInitializing.value = false;
      isPlaying.value = false;
    }
  }

  void _videoListener() {
    if (videoPlayerController == null) return;
    final value = videoPlayerController!.value;

    if (value.hasError) {
      isPlaying.value = false;
      channelStatuses[selectedChannel.value] = 'Connection failed';
      errorMessage.value =
          value.errorDescription ?? 'RTSP stream decoding error.';
    } else if (value.isPlaying && !isPlaying.value) {
      isPlaying.value = true;
      channelStatuses[selectedChannel.value] = 'Live';
      errorMessage.value = '';
    }
  }

  void toggleStreamType() {
    streamType.value = streamType.value == 'main' ? 'sub' : 'main';
    selectCamera(selectedChannel.value);
  }

  void reconnectCurrentCamera() {
    selectCamera(selectedChannel.value);
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (videoPlayerController != null &&
        videoPlayerController!.value.isInitialized) {
      videoPlayerController!.setVolume(isMuted.value ? 0.0 : 1.0);
    }
  }
}
