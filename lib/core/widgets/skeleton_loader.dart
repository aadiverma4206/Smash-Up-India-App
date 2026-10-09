import 'package:flutter/material.dart';

class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonMatchCard extends StatelessWidget {
  const SkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Left Column Skeleton
          const SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonContainer(width: 55, height: 16, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonContainer(width: 65, height: 12, borderRadius: 4),
                SizedBox(height: 10),
                SkeletonContainer(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 65,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 12),
          // Right Column Skeleton
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonContainer(width: 35, height: 16, borderRadius: 4),
                    SizedBox(width: 6),
                    SkeletonContainer(width: 50, height: 16, borderRadius: 4),
                    SizedBox(width: 6),
                    SkeletonContainer(width: 60, height: 16, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonContainer(width: 20, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonContainer(height: 14, borderRadius: 4)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonContainer(width: 50, height: 16, borderRadius: 4),
                    SkeletonContainer(width: 30, height: 20, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  final int count;

  const SkeletonListLoader({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonMatchCard(),
    );
  }
}
