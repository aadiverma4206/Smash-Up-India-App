import 'package:flutter/material.dart';
import 'media_server_cctv_view.dart';

/// Directs all CCTV camera list requests straight to MediaMTX Live Stream Screen.
class CctvListView extends StatelessWidget {
  const CctvListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MediaServerCctvScreen();
  }
}
