import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_colors.dart';
import '../utils/image_utils.dart';

typedef WhatsAppProfileImageViewerPage = ProfileImageViewerPage;

class ProfileImageViewerPage extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onEditTap;

  const ProfileImageViewerPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onEditTap,
  });

  @override
  State<ProfileImageViewerPage> createState() => _ProfileImageViewerPageState();
}

class _ProfileImageViewerPageState extends State<ProfileImageViewerPage> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  void _handleDoubleTap() {
    setState(() {
      if (_currentScale > 1.0) {
        _currentScale = 1.0;
        _transformationController.value = Matrix4.identity();
      } else {
        _currentScale = 2.5;
        _transformationController.value =
            Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValidUrl = widget.imageUrl.isValidNetworkUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Profile photo',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Change Photo',
            onPressed: widget.onEditTap,
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 4.0,
            child: isValidUrl
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                    errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final initial =
        widget.name.trim().isNotEmpty ? widget.name.trim()[0].toUpperCase() : 'P';

    return Container(
      width: 260,
      height: 260,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 100,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
