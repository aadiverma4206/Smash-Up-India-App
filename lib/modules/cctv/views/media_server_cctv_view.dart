import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/env_config.dart';
import '../../../core/network/server_discovery_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../app/theme/app_colors.dart';

class MediaServerCctvScreen extends StatefulWidget {
  final String? initialBaseUrl;

  final int initialChannel;

  const MediaServerCctvScreen({
    super.key,
    this.initialBaseUrl,
    this.initialChannel = 1,
  });

  @override
  State<MediaServerCctvScreen> createState() => _MediaServerCctvScreenState();
}

class _MediaServerCctvScreenState extends State<MediaServerCctvScreen> {
  static const String _prefKeyBaseUrl = 'mediamtx_base_url';

  VideoPlayerController? _controller;
  late TransformationController _transformationController;
  double _currentZoomScale = 1.0;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControlsOverlay = true;
  Timer? _controlsTimer;

  late int _selectedChannel;
  String _selectedQuality = 'sub';

  late String _baseUrl;

  String _activeStreamUrl = '';

  final Map<int, String> _channelNames = {
    1: 'Camera 1 (Court 1 - Main Pitch)',
    2: 'Camera 2 (Court 1 - Sideline)',
    3: 'Camera 3 (Court 2 - Main Pitch)',
    4: 'Camera 4 (Court 2 - Goalpost)',
  };

  static bool _isControllerValid(VideoPlayerController? controller) {
    if (controller == null) return false;
    try {
      return controller.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static double _getControllerAspectRatio(VideoPlayerController? controller) {
    if (controller == null) return 16 / 9;
    try {
      final ratio = controller.value.aspectRatio;
      return ratio > 0 ? ratio : (16 / 9);
    } catch (_) {
      return 16 / 9;
    }
  }

  static String _resolveDefaultBaseUrl([String? initialBaseUrl]) {
    if (initialBaseUrl != null && initialBaseUrl.trim().isNotEmpty) {
      return initialBaseUrl.trim();
    }

    try {
      final envUri = Uri.tryParse(EnvConfig.baseUrl);
      if (envUri != null && envUri.host.isNotEmpty) {
        String host = envUri.host;
        final scheme = envUri.scheme.isNotEmpty ? envUri.scheme : 'http';
        final port =
            envUri.hasPort ? envUri.port : (scheme == 'https' ? 443 : 5000);
        return '$scheme://$host:$port/cctv-stream';
      }
    } catch (_) {}

    return '';
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _selectedChannel =
        (widget.initialChannel >= 1 && widget.initialChannel <= 4)
            ? widget.initialChannel
            : 1;
    _baseUrl = _resolveDefaultBaseUrl(widget.initialBaseUrl);
    _loadSavedBaseUrlAndInitialize();
  }

  void _zoomIn() {
    final double newScale = (_currentZoomScale + 0.5).clamp(1.0, 4.0);
    _setZoomScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentZoomScale - 0.5).clamp(1.0, 4.0);
    _setZoomScale(newScale);
  }

  void _resetZoom() {
    _setZoomScale(1.0);
  }

  void _setZoomScale(double targetScale) {
    setState(() {
      _currentZoomScale = targetScale;
      _transformationController.value =
          Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    });
  }

  void _handleDoubleTap() {
    if (_currentZoomScale > 1.0) {
      _resetZoom();
    } else {
      _setZoomScale(2.5);
    }
  }

  bool _isAutoReconnecting = false;

  Future<void> _loadSavedBaseUrlAndInitialize() async {
    String? cachedTunnel;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKeyBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = savedUrl.trim();
      }
      cachedTunnel = prefs.getString(ServerDiscoveryService.prefKeyTunnelUrl);
    } catch (_) {}
    _initializePlayer(cachedTunnel);
  }

  String get _currentStreamKey => 'cam${_selectedChannel}_$_selectedQuality';

  String get _backendProxyHlsUrl {
    final cleanBase = EnvConfig.baseUrl
        .replaceAll(RegExp(r'/api/v1/?$'), '')
        .replaceAll(RegExp(r'/$'), '');
    return '$cleanBase/cctv-stream/$_currentStreamKey/index.m3u8';
  }

  String get _directMediaMtxHlsUrl {
    try {
      final envUri = Uri.tryParse(EnvConfig.baseUrl);
      if (envUri != null && envUri.host.isNotEmpty) {
        String host = envUri.host;
        return 'http://$host:8888/$_currentStreamKey/index.m3u8';
      }
    } catch (_) {}
    return '';
  }

  List<String> _buildCandidateUrls([String? cachedTunnelUrl]) {
    final candidates = <String>[];

    if (_baseUrl.isNotEmpty) {
      final clean = _baseUrl.replaceAll(RegExp(r'/$'), '');
      final customUrl = clean.contains('/cam')
          ? clean
          : '$clean/$_currentStreamKey/index.m3u8';
      if (!candidates.contains(customUrl)) {
        candidates.add(customUrl);
      }
    }

    final proxyUrl = _backendProxyHlsUrl;
    if (proxyUrl.isNotEmpty && !candidates.contains(proxyUrl)) {
      candidates.add(proxyUrl);
    }

    final directUrl = _directMediaMtxHlsUrl;
    if (directUrl.isNotEmpty && !candidates.contains(directUrl)) {
      candidates.add(directUrl);
    }

    return candidates;
  }

  void _handleStreamRuntimeError(String? errorDescription) {
    if (!mounted || _isAutoReconnecting) return;
    _isAutoReconnecting = true;
    AppLogger.warning(
        '⚠️ [CCTV Stream] Connection lost or WiFi changed: $errorDescription. Auto-reconnecting...');

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network changed. Reconnecting...';
      });
    }

    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      await _initializePlayer();
      _isAutoReconnecting = false;
    });
  }

  Future<void> _initializePlayer([String? cachedTunnelUrl]) async {
    if (!mounted) return;

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      try {
        await oldController.pause();
        await oldController.dispose();
      } catch (_) {}
    }

    final candidates = _buildCandidateUrls(cachedTunnelUrl);

    String lastError = '';

    for (final candidateUrl in candidates) {
      if (!mounted) return;

      VideoPlayerController? tempController;
      try {
        AppLogger.info('📡 [CCTV Stream] Trying candidate: $candidateUrl');
        final uri = Uri.parse(candidateUrl);
        tempController = VideoPlayerController.networkUrl(
          uri,
          formatHint: VideoFormat.hls,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );

        await tempController.initialize().timeout(const Duration(seconds: 10));
        await tempController.setVolume(0.0);
        await tempController.play();

        if (!mounted) {
          await tempController.dispose();
          return;
        }

        final activeController = tempController;
        activeController.addListener(() {
          if (!mounted) return;
          try {
            if (activeController.value.hasError && !_hasError) {
              _handleStreamRuntimeError(
                  activeController.value.errorDescription);
            }
          } catch (_) {}
        });

        _activeStreamUrl = candidateUrl;

        final workingBase = candidateUrl.replaceAll(
          RegExp(r'/cam\d+_(sub|main)/index\.m3u8.*$'),
          '',
        );
        if (workingBase != _baseUrl) {
          _baseUrl = workingBase;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyBaseUrl, _baseUrl);
          } catch (_) {}
        }

        AppLogger.info(
            '✅ [CCTV Stream] Live video stream connected: $candidateUrl');

        setState(() {
          _controller = activeController;
          _isInitialized = true;
          _hasError = false;
        });
        return;
      } catch (e) {
        lastError = e.toString();
        AppLogger.warning(
            '❌ [CCTV Stream] Candidate failed: $candidateUrl ($e)');
        if (tempController != null) {
          try {
            await tempController.pause();
            await tempController.dispose();
          } catch (_) {}
        }
      }
    }

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = lastError;
      });
    }
  }

  void _toggleControlsOverlayVisibility() {
    setState(() {
      _showControlsOverlay = !_showControlsOverlay;
    });
    if (_showControlsOverlay) {
      _resetControlsTimer();
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControlsOverlay) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showControlsOverlay = false;
          });
        }
      });
    }
  }

  bool _isCurrentlyInFullscreenPage = false;
  bool _isTransitioningFullscreen = false;

  void _openFullscreenPlayer(BuildContext context) async {
    if (_controller == null ||
        !_isInitialized ||
        !_isControllerValid(_controller) ||
        _isTransitioningFullscreen) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    setState(() {
      _isTransitioningFullscreen = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    setState(() {
      _isCurrentlyInFullscreenPage = true;
      _isTransitioningFullscreen = false;
    });

    await navigator.push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (fullscreenContext, animation, secondaryAnimation) {
          return CctvFullscreenPlayerPage(
            controller: _controller!,
            channel: _selectedChannel,
            quality: _selectedQuality,
            channelName:
                _channelNames[_selectedChannel] ?? 'Camera $_selectedChannel',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isTransitioningFullscreen = true;
      });

      await Future.delayed(const Duration(milliseconds: 120));

      if (mounted) {
        setState(() {
          _isCurrentlyInFullscreenPage = false;
          _isTransitioningFullscreen = false;
        });
      }
    }
  }

  void _switchChannel(int channel) {
    if (_selectedChannel == channel) return;
    setState(() {
      _selectedChannel = channel;
    });
    _initializePlayer();
  }

  void _switchQuality(String quality) {
    if (_selectedQuality == quality) return;
    setState(() {
      _selectedQuality = quality;
    });
    _initializePlayer();
  }

  Future<void> _saveBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty) return;
    setState(() {
      _baseUrl = cleanUrl;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBaseUrl, cleanUrl);
    } catch (_) {}
    _initializePlayer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _transformationController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_controller != null) {
      try {
        _controller!.pause();
        _controller!.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = context.backgroundColor;
    final cardColor = context.cardColor;
    final borderColor = context.borderColor;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final inputBg = context.inputBgColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _isInitialized
                    ? const Color(0xFF10B981)
                    : (_hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isInitialized
                            ? const Color(0xFF10B981)
                            : (_hasError
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B)))
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'CCTV Live • CH $_selectedChannel',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            (isDark ? AppColors.darkAppBar : AppColors.sageGreenAppBar),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: _initializePlayer,
            tooltip: 'Reload Stream',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlayerContent(),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 16, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Stream Quality:',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQualityChip(
                              'SD (Sub)', 'sub', Icons.speed_rounded, context),
                          const SizedBox(width: 8),
                          _buildQualityChip(
                              'HD (1080p)', 'main', Icons.hd_rounded, context),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Camera Channel:',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth > 550 ? 4 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          childAspectRatio: crossCount == 4 ? 2.6 : 2.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final ch = index + 1;
                          final isSelected = _selectedChannel == ch;
                          final camName = _channelNames[ch] ?? 'Camera $ch';

                          return InkWell(
                            onTap: () => _switchChannel(ch),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                        .withValues(alpha: isDark ? 0.25 : 0.12)
                                    : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : borderColor,
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : inputBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'CH $ch',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: const Color(0xFF10B981),
                                                width: 0.8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.fiber_manual_record,
                                                  color: Color(0xFF10B981),
                                                  size: 6),
                                              SizedBox(width: 3),
                                              Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Icon(Icons.videocam_outlined,
                                            color: textSecondary, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    camName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.white
                                              : AppColors.primaryDark)
                                          : textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isTransitioningFullscreen) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Optimizing Live View...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCurrentlyInFullscreenPage) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Playing in Fullscreen Mode',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          color: Color(0xFFEF4444), size: 36),
                      const SizedBox(height: 6),
                      Text(
                        'Failed to load Channel $_selectedChannel Stream',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activeStreamUrl.isNotEmpty
                            ? 'Attempting connection across LAN and Cloud Tunnel...'
                            : 'Ensure Camera DVR (192.168.1.2) is powered on and connected.',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFF87171), fontSize: 10),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              setState(() {
                                _isInitialized = false;
                                _hasError = false;
                              });
                              await _loadSavedBaseUrlAndInitialize();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Retry Auto-Connect',
                                style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _showUrlDialog,
                            icon: const Icon(Icons.tune_rounded, size: 14),
                            label: const Text('Change URL',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (!_isInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.8,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Connecting to MediaMTX Stream (CH $_selectedChannel)...',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final bool isPlayerReady =
        _isControllerValid(_controller) && _isInitialized;
    final double videoRatio = _getControllerAspectRatio(_controller);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _handleDoubleTap,
      onTap: _toggleControlsOverlayVisibility,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: isPlayerReady
                  ? InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      clipBehavior: Clip.hardEdge,
                      transformationController: _transformationController,
                      child: AspectRatio(
                        aspectRatio: videoRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
            ),
          ),
          AnimatedOpacity(
            opacity: _showControlsOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !_showControlsOverlay,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        top: false,
                        left: true,
                        right: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record,
                                        color: Colors.white, size: 8),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.white24, width: 0.8),
                                  ),
                                  child: Text(
                                    'CH $_selectedChannel • ${_selectedQuality == 'sub' ? 'SD' : 'HD 1080p'}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        left: true,
                        right: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white24, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: _zoomOut,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.zoom_out_rounded,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Text(
                                        '${_currentZoomScale.toStringAsFixed(1)}x',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _zoomIn,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.zoom_in_rounded,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                    if (_currentZoomScale > 1.0) ...[
                                      InkWell(
                                        onTap: _resetZoom,
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.restart_alt_rounded,
                                              color: Colors.white70, size: 15),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _openFullscreenPlayer(context),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white24, width: 0.8),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityChip(
      String label, String qualityKey, IconData icon, BuildContext context) {
    final isSelected = _selectedQuality == qualityKey;
    final cardColor = context.cardColor;
    final borderColor = context.borderColor;
    final textSecondary = context.textSecondary;

    return InkWell(
      onTap: () => _switchQuality(qualityKey),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final textController = TextEditingController(text: _baseUrl);
    final envUri = Uri.tryParse(EnvConfig.baseUrl);
    final envHost = envUri?.host ?? '';
    final cleanBackend = EnvConfig.baseUrl
        .replaceAll(RegExp(r'/api/v1/?$'), '')
        .replaceAll(RegExp(r'/$'), '');

    final presets = <Map<String, String>>[
      {
        'label': 'Universal Proxy (Port 5000)',
        'sub': 'Mobile Data / All Networks',
        'url': '$cleanBackend/cctv-stream',
      },
      if (envHost.isNotEmpty &&
          envHost != 'localhost' &&
          envHost != '127.0.0.1')
        {
          'label': 'Direct MediaMTX (Port 8888)',
          'sub': 'Local WiFi / LAN',
          'url': 'http://$envHost:8888',
        },
      if (!kIsWeb && Platform.isAndroid)
        {
          'label': 'Android Emulator',
          'sub': '10.0.2.2',
          'url': 'http://10.0.2.2:5000/cctv-stream',
        },
      {
        'label': 'Localhost / Reverse ADB',
        'sub': '127.0.0.1',
        'url': 'http://127.0.0.1:5000/cctv-stream',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = dialogCtx.isDark;
            final cardColor = dialogCtx.cardColor;
            final borderColor = dialogCtx.borderColor;
            final textPrimary = dialogCtx.textPrimary;
            final textSecondary = dialogCtx.textSecondary;
            final inputBg = dialogCtx.inputBgColor;
            final currentInput = textController.text.trim();

            return Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor, width: 1.2),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.dns_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Media Server Address',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Configure MediaMTX HLS Host',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Enter the base URL where MediaMTX HLS port 8888 is reachable:',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: TextField(
                        controller: textController,
                        onChanged: (_) => setDialogState(() {}),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          hintText: 'http://10.0.2.2:8888',
                          hintStyle:
                              TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          suffixIcon: currentInput.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.cancel,
                                      color: textSecondary, size: 18),
                                  onPressed: () {
                                    textController.clear();
                                    setDialogState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Quick Network Presets:',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: presets.map((preset) {
                        final isCurrent = currentInput == preset['url'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            onTap: () {
                              textController.text = preset['url']!;
                              setDialogState(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                        .withValues(alpha: isDark ? 0.3 : 0.12)
                                    : inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : borderColor,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCurrent
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 16,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          preset['label']!,
                                          style: TextStyle(
                                            color: isCurrent
                                                ? (isDark
                                                    ? Colors.white
                                                    : AppColors.primaryDark)
                                                : textPrimary,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        Text(
                                          preset['url']!,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 10.5,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      preset['sub']!,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Save & Connect',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          onPressed: () {
                            final newUrl = textController.text.trim();
                            if (newUrl.isNotEmpty) {
                              Navigator.pop(ctx);
                              _saveBaseUrl(newUrl);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }
}

class CctvFullscreenPlayerPage extends StatefulWidget {
  final VideoPlayerController controller;
  final int channel;
  final String quality;
  final String channelName;

  const CctvFullscreenPlayerPage({
    super.key,
    required this.controller,
    required this.channel,
    required this.quality,
    required this.channelName,
  });

  @override
  State<CctvFullscreenPlayerPage> createState() =>
      _CctvFullscreenPlayerPageState();
}

class _CctvFullscreenPlayerPageState extends State<CctvFullscreenPlayerPage> {
  bool _showOverlay = true;
  Timer? _overlayTimer;
  late TransformationController _transformationController;
  double _currentZoomScale = 1.0;
  bool _isExitingFullscreen = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _resetOverlayTimer();
  }

  void _restoreSystemUIAndOrientations() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _handleExitFullscreen(BuildContext context) async {
    if (_isExitingFullscreen) return;
    setState(() {
      _isExitingFullscreen = true;
    });

    _restoreSystemUIAndOrientations();

    await Future.delayed(const Duration(milliseconds: 100));

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _transformationController.dispose();
    _restoreSystemUIAndOrientations();
    super.dispose();
  }

  void _zoomIn() {
    final double newScale = (_currentZoomScale + 0.5).clamp(1.0, 4.0);
    _setZoomScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentZoomScale - 0.5).clamp(1.0, 4.0);
    _setZoomScale(newScale);
  }

  void _resetZoom() {
    _setZoomScale(1.0);
  }

  void _setZoomScale(double targetScale) {
    setState(() {
      _currentZoomScale = targetScale;
      _transformationController.value =
          Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    });
  }

  void _handleDoubleTap() {
    if (_currentZoomScale > 1.0) {
      _resetZoom();
    } else {
      _setZoomScale(2.5);
    }
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    if (_showOverlay) {
      _resetOverlayTimer();
    }
  }

  void _resetOverlayTimer() {
    _overlayTimer?.cancel();
    if (_showOverlay) {
      _overlayTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showOverlay = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExitingFullscreen) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Restoring View...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isControllerValid =
        _MediaServerCctvScreenState._isControllerValid(widget.controller);
    final double videoRatio =
        _MediaServerCctvScreenState._getControllerAspectRatio(
            widget.controller);

    Widget playerBody = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _handleDoubleTap,
      onTap: _toggleOverlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: isControllerValid
                  ? InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      clipBehavior: Clip.hardEdge,
                      transformationController: _transformationController,
                      child: AspectRatio(
                        aspectRatio: videoRatio,
                        child: VideoPlayer(widget.controller),
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
            ),
          ),
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showOverlay,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        top: true,
                        left: true,
                        right: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Material(
                                color: Colors.black45,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      _handleExitFullscreen(context),
                                  tooltip: 'Exit Fullscreen',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record,
                                        color: Colors.white, size: 8),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.white24, width: 0.8),
                                  ),
                                  child: Text(
                                    '${widget.channelName} • ${widget.quality == 'sub' ? 'SD' : 'HD 1080p'}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: true,
                        left: true,
                        right: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white24, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: _zoomOut,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.zoom_out_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Text(
                                        '${_currentZoomScale.toStringAsFixed(1)}x',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _zoomIn,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.zoom_in_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                    if (_currentZoomScale > 1.0) ...[
                                      InkWell(
                                        onTap: _resetZoom,
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.restart_alt_rounded,
                                              color: Colors.white70, size: 16),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _handleExitFullscreen(context),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white24, width: 0.8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fullscreen_exit_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Exit Fullscreen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _restoreSystemUIAndOrientations();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: playerBody,
      ),
    );
  }
}
