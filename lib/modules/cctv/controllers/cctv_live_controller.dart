import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../repositories/cctv_repository.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/utils/app_logger.dart';

/// Controller for dynamic live CCTV direct RTSP playback using MediaKit native textures.
class CctvLiveController extends GetxController {
  final CctvRepository repository = Get.find<CctvRepository>();

  final RxList<CctvLiveCameraOptionModel> cameraOptions =
      <CctvLiveCameraOptionModel>[].obs;
  final RxInt selectedChannel = 1.obs;

  // Default to 'sub' stream (lower bitrate, optimized for mobile)
  final RxString streamType = 'sub'.obs;

  final Rxn<CctvLiveSessionModel> currentSession = Rxn<CctvLiveSessionModel>();
  final RxMap<int, String> channelStatuses = <int, String>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingChannel = false.obs;
  final RxBool isPlayerInitializing = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxBool isMuted = true.obs;
  final RxString errorMessage = ''.obs;

  Player? player;
  VideoController? videoController;

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

  /// Helper to redact embedded credentials from RTSP URLs for safe logging and UI display.
  String sanitizeRtspUrl(String raw) {
    if (raw.isEmpty) return raw;
    return raw.replaceAll(RegExp(r'rtsp://[^@]+@'), 'rtsp://***:***@');
  }

  Future<void> _disposePlayer() async {
    final playerToDispose = player;
    player = null;
    videoController = null;
    if (playerToDispose != null) {
      try {
        await playerToDispose.dispose();
      } catch (e) {
        AppLogger.warning('Safe dispose MediaKit Player: $e');
      }
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
    if (isLoadingChannel.value && selectedChannel.value == channel) return;

    isLoadingChannel.value = true;
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
            'DVR Host is unreachable from the court network.\n'
            'Please verify camera power and network connectivity.';
        isPlayerInitializing.value = false;
        isLoadingChannel.value = false;
        return;
      }

      final rtspStreamUrl = session.playbackUrl;

      if (rtspStreamUrl.isEmpty) {
        channelStatuses[channel] = 'Offline';
        errorMessage.value =
            'Unable to generate RTSP stream URL for Channel $channel.';
        isPlayerInitializing.value = false;
        isLoadingChannel.value = false;
        return;
      }

      final sanitizedLogUrl = sanitizeRtspUrl(rtspStreamUrl);
      AppLogger.info(
          'Connecting MediaKit Player to Channel $channel (${streamType.value.toUpperCase()}): $sanitizedLogUrl');

      final newPlayer = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
        ),
      );

      final newVideoController = VideoController(newPlayer);

      player = newPlayer;
      videoController = newVideoController;

      newPlayer.stream.playing.listen((playing) {
        if (playing && !isPlaying.value) {
          isPlaying.value = true;
          channelStatuses[channel] = 'Live';
          errorMessage.value = '';
        }
      });

      newPlayer.stream.error.listen((err) {
        if (err.isNotEmpty) {
          isPlaying.value = false;
          channelStatuses[channel] = 'Connection failed';
          errorMessage.value = sanitizeRtspUrl(err);
        }
      });

      await newPlayer.open(Media(rtspStreamUrl));
      if (isMuted.value) {
        await newPlayer.setVolume(0.0);
      } else {
        await newPlayer.setVolume(100.0);
      }

      isPlaying.value = true;
      channelStatuses[channel] = 'Live';
      errorMessage.value = '';
      isPlayerInitializing.value = false;
    } catch (e) {
      final errStr = sanitizeRtspUrl(e.toString());
      AppLogger.error('Failed to initialize live camera RTSP session: $errStr');

      channelStatuses[channel] = 'Connection failed';
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 403) {
          errorMessage.value =
              'Access Denied: Live CCTV is only accessible to Managers and Admins.';
        } else if (statusCode == 504) {
          errorMessage.value =
              'DVR is unreachable from the backend server.\n'
              'Please check court network connectivity.';
        } else if (statusCode == 401) {
          errorMessage.value = 'Session expired. Please log in again.';
        } else {
          errorMessage.value =
              'Connection failed (HTTP $statusCode): ${e.response?.statusMessage ?? "Server error"}';
        }
      } else {
        errorMessage.value =
            'Connection failed: ${errStr.replaceAll('Exception: ', '').replaceAll('PlatformException(', '').replaceAll(')', '')}';
      }
      isPlayerInitializing.value = false;
      isPlaying.value = false;
    } finally {
      isLoadingChannel.value = false;
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
    if (player != null) {
      player!.setVolume(isMuted.value ? 0.0 : 100.0);
    }
  }
}
