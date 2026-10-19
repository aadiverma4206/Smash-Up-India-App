import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'media_server_cctv_view.dart';

/// Directs all live CCTV stream requests straight to MediaMTX Live Stream Screen.
class CctvLiveView extends StatelessWidget {
  const CctvLiveView({super.key});

  @override
  Widget build(BuildContext context) {
    int chan = 1;
    final args = Get.arguments;
    if (args is Map && args['channel'] != null) {
      chan = (args['channel'] as num).toInt();
    } else if (args is int) {
      chan = args;
    }
    return MediaServerCctvScreen(initialChannel: chan);
  }
}
