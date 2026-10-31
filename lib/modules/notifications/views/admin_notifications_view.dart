import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../player/controllers/notifications_controller.dart';

enum AdminNotificationCategory {
  userCreated,
  matchCreated,
  matchCancelled,
  matchCompleted,
  unknown,
}

class AdminNotificationsView extends GetView<NotificationsController> {
  AdminNotificationsView({super.key});

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryFilter = 'ALL'.obs;

  String _formatTimeAgo(String createdAt) {
    return AppDateUtils.formatRelativeTime(createdAt);
  }

  AdminNotificationCategory _getCategory(NotificationModel n) {
    final type = n.type.toUpperCase();
    final title = n.title.toLowerCase();
    final body = n.body.toLowerCase();

    // 1. User Account Created
    if (type.contains('USER') ||
        type.contains('REGISTER') ||
        type.contains('ACCOUNT') ||
        title.contains('user') ||
        title.contains('account') ||
        title.contains('register') ||
        body.contains('account registered') ||
        body.contains('player created') ||
        body.contains('manager created')) {
      return AdminNotificationCategory.userCreated;
    }

    // 2. Match Created
    if (type.contains('MATCH_CREATED') ||
        (type.contains('MATCH') &&
            (title.contains('created') || body.contains('created'))) ||
        (type.contains('GAME') &&
            (title.contains('created') || body.contains('created'))) ||
        title.contains('match created') ||
        title.contains('game created') ||
        body.contains('match created')) {
      return AdminNotificationCategory.matchCreated;
    }

    // 3. Match Cancelled & Refunded
    if (type.contains('CANCEL') ||
        type.contains('REFUND') ||
        title.contains('cancel') ||
        title.contains('refund') ||
        body.contains('cancelled') ||
        body.contains('refund')) {
      return AdminNotificationCategory.matchCancelled;
    }

    // 4. Match Completed
    if (type.contains('MATCH_COMPLETED') ||
        (type.contains('MATCH') &&
            (title.contains('complete') || body.contains('completed'))) ||
        title.contains('match completed') ||
        title.contains('game completed') ||
        body.contains('completed') ||
        body.contains('final score')) {
      return AdminNotificationCategory.matchCompleted;
    }

    return AdminNotificationCategory.unknown;
  }

  bool _isAllowedAdminNotification(NotificationModel n) {
    return _getCategory(n) != AdminNotificationCategory.unknown;
  }

  Color _getCategoryBgColor(AdminNotificationCategory cat, bool isDark) {
    switch (cat) {
      case AdminNotificationCategory.userCreated:
        return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
      case AdminNotificationCategory.matchCreated:
        return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
      case AdminNotificationCategory.matchCancelled:
        return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
      case AdminNotificationCategory.matchCompleted:
        return isDark ? const Color(0xFF2E2412) : const Color(0xFFFEF8E8);
      case AdminNotificationCategory.unknown:
        return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
    }
  }

  Color _getCategoryIconColor(AdminNotificationCategory cat) {
    switch (cat) {
      case AdminNotificationCategory.userCreated:
        return const Color(0xFF8E24AA);
      case AdminNotificationCategory.matchCreated:
        return const Color(0xFF00C853);
      case AdminNotificationCategory.matchCancelled:
        return const Color(0xFFE53935);
      case AdminNotificationCategory.matchCompleted:
        return const Color(0xFFFFB300);
      case AdminNotificationCategory.unknown:
        return const Color(0xFF1E88E5);
    }
  }

  IconData _getCategoryIcon(AdminNotificationCategory cat) {
    switch (cat) {
      case AdminNotificationCategory.userCreated:
        return Icons.person_add_rounded;
      case AdminNotificationCategory.matchCreated:
        return Icons.add_circle_outline_rounded;
      case AdminNotificationCategory.matchCancelled:
        return Icons.cancel_outlined;
      case AdminNotificationCategory.matchCompleted:
        return Icons.emoji_events_rounded;
      case AdminNotificationCategory.unknown:
        return Icons.notifications_active_outlined;
    }
  }

  String _getCategoryBadgeLabel(AdminNotificationCategory cat) {
    switch (cat) {
      case AdminNotificationCategory.userCreated:
        return 'USER CREATED';
      case AdminNotificationCategory.matchCreated:
        return 'MATCH CREATED';
      case AdminNotificationCategory.matchCancelled:
        return 'CANCELLED & REFUNDED';
      case AdminNotificationCategory.matchCompleted:
        return 'MATCH COMPLETED';
      case AdminNotificationCategory.unknown:
        return 'SYSTEM';
    }
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

        return AppBar(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.sageGreenAppBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Admin Notifications',
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
      final categoryFilter = selectedCategoryFilter.value;

      final allowedNotifications =
          controller.notifications.where(_isAllowedAdminNotification).toList();

      final filtered = allowedNotifications.where((n) {
        final cat = _getCategory(n);
        if (categoryFilter != 'ALL') {
          if (categoryFilter == 'USER' &&
              cat != AdminNotificationCategory.userCreated) {
            return false;
          }
          if (categoryFilter == 'CREATED' &&
              cat != AdminNotificationCategory.matchCreated) {
            return false;
          }
          if (categoryFilter == 'CANCELLED' &&
              cat != AdminNotificationCategory.matchCancelled) {
            return false;
          }
          if (categoryFilter == 'COMPLETED' &&
              cat != AdminNotificationCategory.matchCompleted) {
            return false;
          }
        }

        if (query.isNotEmpty) {
          return n.title.toLowerCase().contains(query) ||
              n.body.toLowerCase().contains(query);
        }
        return true;
      }).toList();

      final visibleIds = filtered.map((n) => n.id).toList();

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, visibleIds),
        body: ResponsiveBuilder(
          builder: (context, deviceType) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: '',
                        hint: 'Search Notifications by title or details...',
                        controller: searchController,
                        prefixIcon: const Icon(Icons.search_rounded,
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
                      _buildCategoryFilterChips(context),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value &&
                              controller.notifications.isEmpty) {
                            return _buildShimmerView(context, deviceType);
                          }

                          if (filtered.isEmpty) {
                            return RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async =>
                                  controller.fetchNotifications(isRefresh: true),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.of(context).size.height *
                                            0.4,
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.notifications_off_outlined,
                                          size: 48,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No admin notifications found',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : const Color(0xFF111827),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Try clearing your search query or selecting a different category filter.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async =>
                                controller.fetchNotifications(isRefresh: true),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 850) {
                                  return GridView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics()),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 560,
                                      mainAxisExtent: 130,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildNotificationTile(
                                          context, filtered[index]);
                                    },
                                  );
                                }
                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics()),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _buildNotificationTile(
                                        context, filtered[index]);
                                  },
                                );
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

  Widget _buildCategoryFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final allowed =
          controller.notifications.where(_isAllowedAdminNotification).toList();

      final countAll = allowed.length;
      final countUser = allowed
          .where(
              (n) => _getCategory(n) == AdminNotificationCategory.userCreated)
          .length;
      final countCreated = allowed
          .where(
              (n) => _getCategory(n) == AdminNotificationCategory.matchCreated)
          .length;
      final countCancelled = allowed
          .where((n) =>
              _getCategory(n) == AdminNotificationCategory.matchCancelled)
          .length;
      final countCompleted = allowed
          .where((n) =>
              _getCategory(n) == AdminNotificationCategory.matchCompleted)
          .length;

      final current = selectedCategoryFilter.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('ALL', 'All ($countAll)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'USER', '1. User Created ($countUser)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'CREATED', '2. Match Created ($countCreated)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip('CANCELLED',
                '3. Cancelled & Refunded ($countCancelled)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip('COMPLETED',
                '4. Match Completed ($countCompleted)', current, isDark),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(
      String code, String label, String current, bool isDark) {
    final isSelected = current == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => selectedCategoryFilter.value = code,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _getCategory(item);
    final bgColor = _getCategoryBgColor(category, isDark);
    final iconColor = _getCategoryIconColor(category);
    final iconData = _getCategoryIcon(category);
    final badgeLabel = _getCategoryBadgeLabel(category);
    final timeAgo = _formatTimeAgo(item.createdAt);

    return Obx(() {
      final isSelected = controller.selectedIds.contains(item.id);
      final isSelectionMode = controller.isSelectionMode;

      return Card(
        elevation: isSelected ? 2.0 : 0,
        margin: EdgeInsets.zero,
        color: isSelected
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.primary.withValues(alpha: 0.12))
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (item.isRead
                    ? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
                    : AppColors.primary.withValues(alpha: 0.6)),
            width: isSelected ? 2.0 : (item.isRead ? 1.0 : 1.6),
          ),
        ),
        child: InkWell(
          onTap: () => controller.markAsReadAndNavigate(item),
          onLongPress: () => controller.toggleSelection(item.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (timeAgo.isNotEmpty)
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              item.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 1,
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
                    color: isSelected ? AppColors.primary : Colors.grey,
                    size: 22,
                  ),
                ] else if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
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
    });
  }

  Widget _buildShimmerView(BuildContext context, DeviceType deviceType) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 850) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 560,
              mainAxisExtent: 130,
              crossAxisSpacing: 12,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => _buildSingleShimmerCard(context),
          );
        }
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => _buildSingleShimmerCard(context),
        );
      },
    );
  }

  Widget _buildSingleShimmerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const AppShimmer(
              width: 42, height: 42, shape: BoxShape.circle, enable3D: true),
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
                        width: 100,
                        height: 12,
                        borderRadius: 4,
                        enable3D: true),
                    AppShimmer(
                        width: 45, height: 11, borderRadius: 4, enable3D: true),
                  ],
                ),
                const SizedBox(height: 8),
                const AppShimmer(
                    width: 160, height: 13, borderRadius: 4, enable3D: true),
                const SizedBox(height: 6),
                const AppShimmer(
                    width: 210, height: 11, borderRadius: 4, enable3D: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
