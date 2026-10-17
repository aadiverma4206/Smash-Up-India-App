import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/env_config.dart';

/// Production-ready CCTV Live Stream Player using MediaMTX HLS streams.
/// Connects directly to MediaMTX server (port 8888) with support for Channels 1-4,
/// Low-Latency HLS (LL-HLS), quality switching (SD/HD), Fullscreen, and URL persistence.
class MediaServerCctvScreen extends StatefulWidget {
  /// Base URL where MediaMTX HLS is hosted (e.g. 'http://10.0.2.2:8888' or 'https://cctv.domain.com')
  final String? initialBaseUrl;

  /// Default channel to open (1-4)
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
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFullscreen = false;
  bool _isMuted = true;

  // Selected Channel (1, 2, 3, 4) and Stream Quality ('sub' for SD, 'main' for HD)
  late int _selectedChannel;
  String _selectedQuality = 'sub'; // 'sub' = SD (low latency), 'main' = HD (1080p)

  late String _baseUrl;

  final Map<int, String> _channelNames = {
    1: 'Camera 1 (Court 1 - Main Pitch)',
    2: 'Camera 2 (Court 1 - Sideline)',
    3: 'Camera 3 (Court 2 - Main Pitch)',
    4: 'Camera 4 (Court 2 - Goalpost)',
  };

  /// Smart default base URL resolution based on platform and EnvConfig
  static String _resolveDefaultBaseUrl([String? initialBaseUrl]) {
    if (initialBaseUrl != null && initialBaseUrl.trim().isNotEmpty) {
      return initialBaseUrl.trim();
    }

    try {
      final envUri = Uri.tryParse(EnvConfig.baseUrl);
      if (envUri != null && envUri.host.isNotEmpty) {
        String host = envUri.host;
        // On Android emulator, localhost / 127.0.0.1 routes to 10.0.2.2
        if (host == 'localhost' || host == '127.0.0.1') {
          if (!kIsWeb && Platform.isAndroid) {
            host = '10.0.2.2';
          }
        }
        final scheme = envUri.scheme.isNotEmpty ? envUri.scheme : 'http';
        return '$scheme://$host:8888';
      }
    } catch (_) {}

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8888';
    }
    return 'http://localhost:8888';
  }

  @override
  void initState() {
    super.initState();
    _selectedChannel = (widget.initialChannel >= 1 && widget.initialChannel <= 4)
        ? widget.initialChannel
        : 1;
    _baseUrl = _resolveDefaultBaseUrl(widget.initialBaseUrl);
    _loadSavedBaseUrlAndInitialize();
  }

  Future<void> _loadSavedBaseUrlAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKeyBaseUrl);
      // Ignore obsolete hardcoded '192.168.1.100' placeholder to prevent timeout on emulator/device
      if (savedUrl != null &&
          savedUrl.trim().isNotEmpty &&
          !savedUrl.contains('192.168.1.100')) {
        _baseUrl = savedUrl.trim();
      }
    } catch (_) {}
    _initializePlayer();
  }

  /// Construct stream key based on mediamtx.yml path definitions
  /// e.g. cam1_sub, cam1_main, cam2_sub, cam2_main, etc.
  String get _currentStreamKey => 'cam${_selectedChannel}_$_selectedQuality';

  /// Construct complete HLS playlist URL
  /// e.g. http://10.0.2.2:8888/cam1_sub/index.m3u8
  String get _currentHlsUrl {
    final cleanBase = _baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$cleanBase/$_currentStreamKey/index.m3u8';
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      await oldController.dispose();
    }

    // Build ordered list of candidate URLs to try
    final candidates = <String>[_currentHlsUrl];

    // On Android (emulator or device), add 10.0.2.2 and 127.0.0.1 (adb reverse)
    if (!kIsWeb && Platform.isAndroid) {
      final emuUrl = 'http://10.0.2.2:8888/$_currentStreamKey/index.m3u8';
      final adbUrl = 'http://127.0.0.1:8888/$_currentStreamKey/index.m3u8';
      if (!candidates.contains(emuUrl)) candidates.add(emuUrl);
      if (!candidates.contains(adbUrl)) candidates.add(adbUrl);
    }

    String lastError = '';

    for (final candidateUrl in candidates) {
      if (!mounted) return;

      try {
        final uri = Uri.parse(candidateUrl);
        final controller = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );

        await controller.initialize().timeout(const Duration(seconds: 4));
        await controller.setVolume(_isMuted ? 0.0 : 1.0);
        await controller.play();

        if (!mounted) {
          await controller.dispose();
          return;
        }

        // Successfully connected! Update _baseUrl to working host
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

        setState(() {
          _controller = controller;
          _isInitialized = true;
          _hasError = false;
        });
        return;
      } catch (e) {
        lastError = e.toString();
        // Candidate failed, continuing to next candidate
      }
    }

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = lastError;
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
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

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller?.setVolume(_isMuted ? 0.0 : 1.0);
    });
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildPlayerContent(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isInitialized
                    ? Colors.greenAccent
                    : (_hasError ? Colors.redAccent : Colors.orange),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'MediaMTX CCTV CH $_selectedChannel',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
            onPressed: _toggleMute,
            tooltip: _isMuted ? 'Unmute' : 'Mute',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializePlayer,
            tooltip: 'Reload Stream',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player Box (16:9 Aspect Ratio)
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlayerContent(),
              ),
            ),

            // Controls & Channel Selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stream Quality Selector (SD Substream vs HD Mainstream) - Overflow-safe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Stream Quality:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQualityChip('SD (Sub)', 'sub'),
                          const SizedBox(width: 8),
                          _buildQualityChip('HD (1080p)', 'main'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Camera Channel Grid Options (CH 1-4)
                  const Text(
                    'Select Camera Channel:',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final ch = index + 1;
                      final isSelected = _selectedChannel == ch;
                      final camName = _channelNames[ch] ?? 'Camera $ch';

                      return InkWell(
                        onTap: () => _switchChannel(ch),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent.withValues(alpha: 0.25)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.blueAccent : Colors.white12,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blueAccent : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'CH $ch',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 14),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                camName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Camera Technical Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Camera & Stream Diagnostics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        _buildInfoRow('Active Camera', _channelNames[_selectedChannel] ?? 'CH $_selectedChannel'),
                        _buildInfoRow('Stream Key', _currentStreamKey),
                        _buildInfoRow('Media Server Base', _baseUrl),
                        _buildInfoRow('Full Stream URL', _currentHlsUrl),
                        _buildInfoRow('Protocol', 'Low-Latency HLS (LL-HLS)'),
                        _buildInfoRow(
                          'Stream Status',
                          _isInitialized ? 'ONLINE 🟢' : (_hasError ? 'ERROR 🔴' : 'CONNECTING 🟡'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Server URL Configuration Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.settings_input_component_rounded),
                    label: const Text('Configure MediaMTX Server Address'),
                    onPressed: _showUrlDialog,
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
    if (_hasError) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 36),
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
                        'Ensure MediaMTX is running at $_baseUrl and the camera is online.',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _initializePlayer,
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Retry', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _showUrlDialog,
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            label: const Text('Change URL', style: TextStyle(fontSize: 12)),
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
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(
              'Connecting to MediaMTX Stream (CH $_selectedChannel)...',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio > 0
                ? _controller!.value.aspectRatio
                : 16 / 9,
            child: VideoPlayer(_controller!),
          ),
        ),

        // LIVE status badge overlay (top-left)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // Controls overlay (bottom-right)
        Positioned(
          bottom: 10,
          right: 10,
          child: Row(
            children: [
              IconButton(
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 22),
                onPressed: _toggleMute,
              ),
              IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityChip(String label, String qualityKey) {
    final isSelected = _selectedQuality == qualityKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _switchQuality(qualityKey),
      selectedColor: Colors.blueAccent,
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(
        color: isSelected ? Colors.blueAccent : Colors.white12,
        width: 1,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[300],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog() {
    final textController = TextEditingController(text: _baseUrl);
    final envUri = Uri.tryParse(EnvConfig.baseUrl);
    final envHost = envUri?.host ?? '';

    final presets = <Map<String, String>>[
      {'label': 'Emulator (10.0.2.2)', 'url': 'http://10.0.2.2:8888'},
      if (envHost.isNotEmpty && envHost != '10.0.2.2' && envHost != 'localhost')
        {'label': 'LAN ($envHost)', 'url': 'http://$envHost:8888'},
      {'label': 'Localhost', 'url': 'http://localhost:8888'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Update MediaMTX Base URL', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the address where MediaMTX HLS is hosted (Local IP, DDNS, or Public Tunnel):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8888 or http://192.168.1.x:8888',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                labelText: 'Server Base URL',
                labelStyle: TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Presets:',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: presets.map((preset) {
                return ActionChip(
                  label: Text(preset['label']!, style: const TextStyle(fontSize: 10.5, color: Colors.white)),
                  backgroundColor: const Color(0xFF334155),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    textController.text = preset['url']!;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                Navigator.pop(ctx);
                _saveBaseUrl(newUrl);
              }
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }
}
