import 'dart:async';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:get/get.dart';
import '../repositories/cctv_repository.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/config/env_config.dart';
import '../../../core/utils/app_logger.dart';

class CctvLiveController extends GetxController {
  final CctvRepository repository = Get.find<CctvRepository>();

  final RxList<CctvLiveCameraOptionModel> cameraOptions =
      <CctvLiveCameraOptionModel>[].obs;
  final RxInt selectedChannel = 1.obs;

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

  vp.VideoPlayerController? fallbackVideoPlayerController;
  final RxBool isUsingFallbackPlayer = false.obs;

  Timer? _frameWatchdogTimer;

  @override
  void onInit() {
    super.onInit();
    try {
      MediaKit.ensureInitialized();
    } catch (_) {}

    int? initialChannel;
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args['channel'] != null) {
      initialChannel = (args['channel'] as num).toInt();
    } else if (args is int) {
      initialChannel = args;
    }
    _loadLiveCameras(initialChannel: initialChannel);
  }

  @override
  void onClose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _frameWatchdogTimer?.cancel();
    _disposePlayer();
    _releaseCurrentSession();
    super.onClose();
  }

  String sanitizeStreamUrl(String raw) {
    if (raw.isEmpty) return raw;
    return raw.replaceAll(RegExp(r'rtsp://[^@]+@'), 'rtsp://***:***@');
  }

  String resolveStreamUrl(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;

    final envBase = EnvConfig.baseUrl;
    final envUri = Uri.tryParse(envBase);

    if (rawUrl.startsWith('/')) {
      if (envUri != null && envUri.hasAuthority) {
        return '${envUri.scheme}://${envUri.authority}$rawUrl';
      }
      return '${envBase.replaceAll(RegExp(r'/api/v1.*$'), '')}$rawUrl';
    }

    final rawUri = Uri.tryParse(rawUrl);
    if (rawUri != null && envUri != null && envUri.hasAuthority) {
      if ((rawUri.host == 'localhost' || rawUri.host == '127.0.0.1') &&
          envUri.host != 'localhost' &&
          envUri.host != '127.0.0.1') {
        final targetPort = rawUri.hasPort
            ? rawUri.port
            : (envUri.hasPort ? envUri.port : 5000);
        return '${envUri.scheme}://${envUri.host}:$targetPort${rawUri.path}${rawUri.hasQuery ? '?${rawUri.query}' : ''}';
      }
    }
    return rawUrl;
  }

  Future<void> _disposePlayer() async {
    _frameWatchdogTimer?.cancel();
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

    final fallbackToDispose = fallbackVideoPlayerController;
    fallbackVideoPlayerController = null;
    isUsingFallbackPlayer.value = false;
    if (fallbackToDispose != null) {
      try {
        await fallbackToDispose.dispose();
      } catch (e) {
        AppLogger.warning('Safe dispose Fallback VideoPlayer: $e');
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

  Future<void> _loadLiveCameras({int? initialChannel}) async {
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
      if (initialChannel != null) {
        final targetChan = cameraOptions.any((c) => c.channel == initialChannel)
            ? initialChannel
            : (cameraOptions.isNotEmpty ? cameraOptions.first.channel : 1);
        selectCamera(targetChan);
      }
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

    if ((player != null || fallbackVideoPlayerController != null) &&
        currentSession.value != null &&
        currentSession.value!.channel == channel &&
        currentSession.value!.streamType == streamType.value &&
        selectedChannel.value == channel &&
        isPlaying.value) {
      AppLogger.info(
          'Channel $channel (${streamType.value.toUpperCase()}) is active. Skipping re-init.');
      return;
    }

    if (isLoadingChannel.value) return;

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
        errorMessage.value = 'DVR Host is unreachable from the court network.\n'
            'Please verify camera power and network connectivity.';
        isPlayerInitializing.value = false;
        isLoadingChannel.value = false;
        return;
      }

      var rawStreamUrl = session.playbackUrl;
      if (rawStreamUrl.isEmpty) {
        rawStreamUrl = session.rtspUrl;
      }

      if (rawStreamUrl.isEmpty) {
        channelStatuses[channel] = 'Offline';
        errorMessage.value =
            'Unable to generate video stream URL for Channel $channel.';
        isPlayerInitializing.value = false;
        isLoadingChannel.value = false;
        return;
      }

      final streamUrl = resolveStreamUrl(rawStreamUrl);
      final sanitizedLogUrl = sanitizeStreamUrl(streamUrl);
      AppLogger.info(
          'Connecting Player to Channel $channel (${streamType.value.toUpperCase()}): $sanitizedLogUrl');

      final newPlayer = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
        ),
      );

      if (newPlayer.platform is NativePlayer) {
        final mpv = newPlayer.platform as NativePlayer;
        try {
          await mpv.setProperty('rtsp-transport', 'tcp');
          await mpv.setProperty('network-timeout', '10');
          await mpv.setProperty('hwdec', 'no');
          await mpv.setProperty('profile', 'low-latency');
        } catch (e) {
          AppLogger.warning('mpv property error: $e');
        }
      }

      final newVideoController = VideoController(
        newPlayer,
        configuration: const VideoControllerConfiguration(
          enableHardwareAcceleration: false,
        ),
      );

      player = newPlayer;
      videoController = newVideoController;

      bool hasReceivedVideoFrame = false;

      newPlayer.stream.playing.listen((playing) {
        if (playing && hasReceivedVideoFrame) {
          isPlaying.value = true;
          channelStatuses[channel] = 'Live';
          errorMessage.value = '';
        }
      });

      newPlayer.stream.width.listen((width) {
        if (width != null && width > 0) {
          hasReceivedVideoFrame = true;
          isPlaying.value = true;
          channelStatuses[channel] = 'Live';
          errorMessage.value = '';
        }
      });

      newPlayer.stream.error.listen((err) {
        if (err.isNotEmpty) {
          final sanitizedErr = sanitizeStreamUrl(err);
          AppLogger.error(
              '❌ [CCTV Error] Stream Error: $sanitizedErr (CH $channel)');
          _tryFallbackVideoPlayer(channel, streamUrl);
        }
      });

      await newPlayer.open(Media(streamUrl));

      if (isMuted.value) {
        await newPlayer.setVolume(0.0);
      } else {
        await newPlayer.setVolume(100.0);
      }

      _frameWatchdogTimer?.cancel();
      _frameWatchdogTimer = Timer(const Duration(seconds: 4), () {
        if (!hasReceivedVideoFrame && player != null) {
          AppLogger.warning(
              '⏱️ Frame Watchdog triggered for CH $channel: MediaKit frame stall detected. Switching to fallback player.');
          _tryFallbackVideoPlayer(channel, streamUrl);
        }
      });

      isPlayerInitializing.value = false;
    } catch (e) {
      final errStr = sanitizeStreamUrl(e.toString());
      AppLogger.error('Failed to initialize live camera session: $errStr');
      _tryFallbackVideoPlayer(channel, '');
    } finally {
      isLoadingChannel.value = false;
    }
  }

  Future<void> _tryFallbackVideoPlayer(int channel, String rawUrl) async {
    AppLogger.info(
        'Attempting fallback VideoPlayerController for Channel $channel...');

    final oldFallback = fallbackVideoPlayerController;
    fallbackVideoPlayerController = null;
    if (oldFallback != null) {
      try {
        await oldFallback.pause();
        await oldFallback.dispose();
      } catch (_) {}
    }

    vp.VideoPlayerController? tempVpController;
    try {
      final targetUrl = rawUrl.isNotEmpty
          ? rawUrl
          : 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

      tempVpController = vp.VideoPlayerController.networkUrl(
        Uri.parse(targetUrl),
        videoPlayerOptions: vp.VideoPlayerOptions(mixWithOthers: true),
      );

      await tempVpController.initialize();
      await tempVpController.setVolume(isMuted.value ? 0.0 : 1.0);
      await tempVpController.play();

      fallbackVideoPlayerController = tempVpController;
      isUsingFallbackPlayer.value = true;
      isPlaying.value = true;
      channelStatuses[channel] = 'Live';
      errorMessage.value = '';
      isPlayerInitializing.value = false;
    } catch (e) {
      AppLogger.error('Fallback player failed for CH $channel: $e');
      if (tempVpController != null) {
        try {
          await tempVpController.pause();
          await tempVpController.dispose();
        } catch (_) {}
      }
      channelStatuses[channel] = 'Connection failed';
      errorMessage.value =
          'Unable to render live video feed. Please verify MediaMTX / camera stream connection.';
      isPlayerInitializing.value = false;
      isPlaying.value = false;
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
    if (isFullscreen.value) {
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

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (player != null) {
      player!.setVolume(isMuted.value ? 0.0 : 100.0);
    }
    if (fallbackVideoPlayerController != null) {
      fallbackVideoPlayerController!.setVolume(isMuted.value ? 0.0 : 1.0);
    }
  }
}
