import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../player/controllers/notifications_controller.dart';
import 'notification_detail_view.dart';

class PlayerNotificationsView extends GetView<NotificationsController> {
  PlayerNotificationsView({super.key});

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  String _formatTimeAgo(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  Color _getCategoryBgColor(String type, bool isDark) {
    final t = type.toUpperCase();
    if (t.contains('SUCCESS') || t.contains('MATCH') || t.contains('CONFIRMED')) {
      return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
    }
    if (t.contains('WARNING') || t.contains('ALERT') || t.contains('REFUND') || t.contains('CANCEL')) {
      return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) {
      return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
    }
    return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
  }

  Color _getCategoryIconColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('SUCCESS') || t.contains('MATCH') || t.contains('CONFIRMED')) {
      return const Color(0xFF00C853);
    }
    if (t.contains('WARNING') || t.contains('ALERT') || t.contains('REFUND') || t.contains('CANCEL')) {
      return const Color(0xFFE53935);
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) {
      return const Color(0xFF8E24AA);
    }
    return const Color(0xFF1E88E5);
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('MATCH') || t.contains('GAME')) return Icons.sports_soccer_rounded;
    if (t.contains('REFUND') || t.contains('WALLET') || t.contains('PAYMENT')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) return Icons.videocam_outlined;
    if (t.contains('WARNING') || t.contains('ALERT')) return Icons.warning_amber_rounded;
    return Icons.notifications_active_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchNotifications(isRefresh: true),
            tooltip: 'Refresh Notifications',
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop =
              deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              children: [
                // Filter Search Bar
                AppTextField(
                  label: '',
                  hint: 'Filter Notifications...',
                  controller: searchController,
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                    onPressed: () {
                      searchController.clear();
                      searchQuery.value = '';
                    },
                  ),
                  onChanged: (val) {
                    searchQuery.value = val.trim().toLowerCase();
                  },
                ),
                const SizedBox(height: 12),

                // Notifications List
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value && controller.notifications.isEmpty) {
                      return _buildShimmerView(context, deviceType);
                    }

                    final query = searchQuery.value;
                    final filtered = controller.notifications.where((n) {
                      if (query.isEmpty) return true;
                      return n.title.toLowerCase().contains(query) ||
                          n.body.toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications found.',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => controller.fetchNotifications(isRefresh: true),
                      child: isTabletOrDesktop
                          ? GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: deviceType == DeviceType.desktop ? 3 : 2,
                                childAspectRatio: 2.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationTile(context, filtered[index]);
                              },
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return _buildNotificationTile(context, filtered[index]);
                              },
                            ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getCategoryBgColor(item.type, isDark);
    final iconColor = _getCategoryIconColor(item.type);
    final iconData = _getCategoryIcon(item.type);
    final timeAgo = _formatTimeAgo(item.createdAt);

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isRead
              ? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
              : AppColors.primary.withValues(alpha: 0.4),
          width: item.isRead ? 0.8 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          controller.markAsReadAndNavigate(item);
          Get.to(() => NotificationDetailView(notification: item));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Category Icon Badge (Matching Screenshot UI)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Subtitle Body & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14.5,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeAgo.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerView(BuildContext context, DeviceType deviceType) {
    final isGrid = deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;
    if (isGrid) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: deviceType == DeviceType.desktop ? 3 : 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _buildSingleShimmerCard(context),
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _buildSingleShimmerCard(context),
    );
  }

  Widget _buildSingleShimmerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const AppShimmer(width: 44, height: 44, shape: BoxShape.circle, enable3D: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppShimmer(width: 130, height: 14, borderRadius: 4, enable3D: true),
                    AppShimmer(width: 45, height: 11, borderRadius: 4, enable3D: true),
                  ],
                ),
                const SizedBox(height: 6),
                const AppShimmer(width: 170, height: 11, borderRadius: 4, enable3D: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
