import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../player/controllers/notifications_controller.dart';
import 'notification_detail_view.dart';

class PlayerNotificationsView extends GetView<NotificationsController> {
  PlayerNotificationsView({super.key});

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  String _formatTimeAgo(String createdAt) {
    return AppDateUtils.formatRelativeTime(createdAt);
  }

  Color _getCategoryBgColor(String type, bool isDark) {
    final t = type.toUpperCase();
    if (t.contains('SUCCESS') ||
        t.contains('MATCH') ||
        t.contains('CONFIRMED')) {
      return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
    }
    if (t.contains('WARNING') ||
        t.contains('ALERT') ||
        t.contains('REFUND') ||
        t.contains('CANCEL')) {
      return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) {
      return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
    }
    return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
  }

  Color _getCategoryIconColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('SUCCESS') ||
        t.contains('MATCH') ||
        t.contains('CONFIRMED')) {
      return const Color(0xFF00C853);
    }
    if (t.contains('WARNING') ||
        t.contains('ALERT') ||
        t.contains('REFUND') ||
        t.contains('CANCEL')) {
      return const Color(0xFFE53935);
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) {
      return const Color(0xFF8E24AA);
    }
    return const Color(0xFF1E88E5);
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('MATCH') || t.contains('GAME')) {
      return Icons.sports_soccer_rounded;
    }
    if (t.contains('REFUND') || t.contains('WALLET') || t.contains('PAYMENT')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) {
      return Icons.videocam_outlined;
    }
    if (t.contains('WARNING') || t.contains('ALERT')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.notifications_active_outlined;
  }

  void _showDeleteConfirmation(BuildContext context, List<String> visibleIds) {
    final count = controller.selectedIds.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Delete Notifications?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $count selected notification(s)? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteSelectedNotifications();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, List<String> visibleIds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
        // Selection Mode AppBar
        if (controller.isSelectionMode) {
          final selectedCount = controller.selectedIds.length;
          final isAllSelected =
              controller.selectedIds.containsAll(visibleIds) &&
                  visibleIds.isNotEmpty;

          return AppBar(
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => controller.clearSelection(),
              tooltip: 'Cancel Selection',
            ),
            title: Text(
              '$selectedCount Selected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isAllSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => controller.selectAll(visibleIds),
                tooltip: isAllSelected ? 'Deselect All' : 'Select All',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(context, visibleIds),
                tooltip: 'Delete Selected',
              ),
              const SizedBox(width: 4),
            ],
          );
        }

        // Standard AppBar (NO Delete bin icon, NO Reload icon)
        return AppBar(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.sageGreenAppBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.done_all_rounded,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
              onPressed: () => controller.markAllRead(),
              tooltip: 'Mark All as Read',
            ),
            const SizedBox(width: 4),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final query = searchQuery.value;
      final filtered = controller.notifications.where((n) {
        if (query.isEmpty) return true;
        return n.title.toLowerCase().contains(query) ||
            n.body.toLowerCase().contains(query);
      }).toList();

      final visibleIds = filtered.map((n) => n.id).toList();

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, visibleIds),
        body: ResponsiveBuilder(
          builder: (context, deviceType) {
            final isTabletOrDesktop = deviceType == DeviceType.tablet ||
                deviceType == DeviceType.desktop;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 10.0),
                  child: Column(
                    children: [
                      AppTextField(
                        label: '',
                        hint: 'Filter Notifications...',
                        controller: searchController,
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primary, size: 20),
                        suffixIcon: Obx(() {
                          if (searchQuery.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.grey, size: 20),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                          );
                        }),
                        onChanged: (val) {
                          searchQuery.value = val.trim().toLowerCase();
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value &&
                              controller.notifications.isEmpty) {
                            return _buildShimmerView(context, deviceType);
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No notifications found.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async =>
                                controller.fetchNotifications(isRefresh: true),
                            child: isTabletOrDesktop
                                ? GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          deviceType == DeviceType.desktop
                                              ? 3
                                              : 2,
                                      childAspectRatio: 2.8,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildNotificationTile(
                                          context, filtered[index]);
                                    },
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      return _buildNotificationTile(
                                          context, filtered[index]);
                                    },
                                  ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getCategoryBgColor(item.type, isDark);
    final iconColor = _getCategoryIconColor(item.type);
    final iconData = _getCategoryIcon(item.type);
    final timeAgo = _formatTimeAgo(item.createdAt);

    return Obx(() {
      final isSelected = controller.selectedIds.contains(item.id);
      final isSelectionMode = controller.isSelectionMode;

      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (item.isRead
                    ? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
                    : AppColors.primary.withValues(alpha: 0.5)),
            width: isSelected ? 2.0 : (item.isRead ? 0.8 : 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: AppColors.primary),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.markAsReadAndNavigate(item),
                  onLongPress: () => controller.toggleSelection(item.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        fontWeight: item.isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        fontSize: 14.5,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : const Color(0xFF0F172A),
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
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : Colors.grey.shade500,
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
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : const Color(0xFF475569),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelectionMode) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ] else if (!item.isRead) ...[
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
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildShimmerView(BuildContext context, DeviceType deviceType) {
    final isGrid =
        deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;
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
          const AppShimmer(
              width: 44, height: 44, shape: BoxShape.circle, enable3D: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppShimmer(
                        width: 130,
                        height: 14,
                        borderRadius: 4,
                        enable3D: true),
                    AppShimmer(
                        width: 45, height: 11, borderRadius: 4, enable3D: true),
                  ],
                ),
                const SizedBox(height: 6),
                const AppShimmer(
                    width: 170, height: 11, borderRadius: 4, enable3D: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
