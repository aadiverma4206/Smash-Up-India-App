import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:get/get.dart';
import '../repositories/cctv_repository.dart';
import '../../../data/models/cctv_models.dart';
import '../../../core/utils/app_logger.dart';

class CctvLiveController extends GetxController {
  final CctvRepository repository = Get.find<CctvRepository>();

  final RxList<CctvLiveCameraOptionModel> cameraOptions =
      <CctvLiveCameraOptionModel>[].obs;
  final RxInt selectedChannel = 1.obs;
  final RxString streamType = 'main'.obs; // 'main' (HD) or 'sub' (SD)
  final Rxn<CctvLiveSessionModel> currentSession = Rxn<CctvLiveSessionModel>();
  final RxMap<int, String> channelStatuses = <int, String>{
    1: 'Connecting',
    2: 'Connecting',
    3: 'Connecting',
    4: 'Connecting',
  }.obs;

  final RxBool isLoading = false.obs;
  final RxBool isPlayerInitializing = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxString errorMessage = ''.obs;

  VlcPlayerController? vlcPlayerController;

  @override
  void onInit() {
    super.onInit();
    _loadLiveCamerasAndConnect(1);
  }

  @override
  void onClose() {
    _disposePlayer();
    _releaseCurrentSession();
    super.onClose();
  }

  Future<void> _disposePlayer() async {
    if (vlcPlayerController != null) {
      try {
        vlcPlayerController!.removeListener(_vlcListener);
        await vlcPlayerController!.stop();
        await vlcPlayerController!.dispose();
      } catch (e) {
        AppLogger.warning('Error disposing VLC player: $e');
      }
      vlcPlayerController = null;
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
      selectCamera(initialChannel);
    }
  }

  void _populateDefaultChannels() {
    cameraOptions.assignAll([
      CctvLiveCameraOptionModel(
          id: 'cam_1', channel: 1, name: 'Camera 1 (Main Pitch)', courtName: 'Court 1'),
      CctvLiveCameraOptionModel(
          id: 'cam_2', channel: 2, name: 'Camera 2 (Side Pitch)', courtName: 'Court 2'),
      CctvLiveCameraOptionModel(
          id: 'cam_3', channel: 3, name: 'Camera 3 (Goal View A)', courtName: 'Court 1'),
      CctvLiveCameraOptionModel(
          id: 'cam_4', channel: 4, name: 'Camera 4 (Goal View B)', courtName: 'Court 2'),
    ]);
  }

  Future<void> selectCamera(int channel) async {
    if (channel < 1 || channel > 4) return;
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
            'DVR Host (192.168.1.2:554) is offline or unreachable on local network.';
        isPlayerInitializing.value = false;
        return;
      }

      final rtspUrl = session.rtspUrl;
      AppLogger.info('Connecting VLC player to RTSP channel $channel stream...');

      vlcPlayerController = VlcPlayerController.network(
        rtspUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          rtsp: VlcRtspOptions([
            '--rtsp-tcp',
          ]),
          advanced: VlcAdvancedOptions([
            '--network-caching=300',
          ]),
        ),
      );

      vlcPlayerController!.addListener(_vlcListener);
    } catch (e) {
      AppLogger.error('Failed to initialize live camera session: $e');
      channelStatuses[channel] = 'Connection failed';
      errorMessage.value =
          'Connection failed: ${e.toString().replaceAll('Exception: ', '')}';
      isPlayerInitializing.value = false;
    }
  }

  void _vlcListener() {
    if (vlcPlayerController == null) return;
    final state = vlcPlayerController!.value;

    if (state.isInitialized) {
      isPlayerInitializing.value = false;
    }

    if (state.isPlaying) {
      isPlaying.value = true;
      channelStatuses[selectedChannel.value] = 'Live';
      errorMessage.value = '';
    } else if (state.hasError) {
      isPlaying.value = false;
      channelStatuses[selectedChannel.value] = 'Connection failed';
      errorMessage.value = state.errorDescription.isNotEmpty
          ? state.errorDescription
          : 'Stream decoding error or RTSP connection lost.';
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
}
