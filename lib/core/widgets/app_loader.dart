import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppLoader extends StatefulWidget {
  final String? message;

  const AppLoader({super.key, this.message});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3.5,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 14),
            Text(
              widget.message!,
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
