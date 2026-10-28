import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/notifications_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/widgets/empty_state.dart';

class PlayerNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color iconBgLight;
  final Color iconBgDark;
  final DateTime dateTime;
  final bool isRead;
  final Map<String, dynamic>? data;

  PlayerNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBgLight,
    required this.iconBgDark,
    required this.dateTime,
    required this.isRead,
    this.data,
  });

  PlayerNotificationItem copyWith({bool? isRead}) {
    return PlayerNotificationItem(
      id: id,
      title: title,
      subtitle: subtitle,
      badgeText: badgeText,
      badgeBgColor: badgeBgColor,
      badgeTextColor: badgeTextColor,
      category: category,
      icon: icon,
      iconColor: iconColor,
      iconBgLight: iconBgLight,
      iconBgDark: iconBgDark,
      dateTime: dateTime,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class PlayerNotificationView extends StatefulWidget {
  const PlayerNotificationView({super.key});

  @override
  State<PlayerNotificationView> createState() => _PlayerNotificationViewState();
}

class _PlayerNotificationViewState extends State<PlayerNotificationView> {
  late final NotificationsController _controller;
  final TextEditingController _searchController = TextEditingController();

  final RxString _searchQuery = ''.obs;
  final RxString _selectedActivity = 'All activity'.obs;
  final RxString _selectedDateFilter = 'Date: All time'.obs;
  final RxBool _showUnreadOnly = false.obs;
  final Rxn<DateTime> _customDate = Rxn<DateTime>();

  final RxList<PlayerNotificationItem> _localItems =
      <PlayerNotificationItem>[].obs;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());

    _loadAndPrepareItems();

    ever(_controller.notifications, (_) {
      _loadAndPrepareItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAndPrepareItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final items = <PlayerNotificationItem>[];

    if (_controller.notifications.isNotEmpty) {
      for (final raw in _controller.notifications) {
        final parsedDt = AppDateUtils.parseDate(raw.createdAt) ?? now;
        items.add(_mapModelToPlayerItem(raw, parsedDt));
      }
    } else {
      items.addAll([
        PlayerNotificationItem(
          id: 'mock_1',
          title: 'New match awaiting approval',
          subtitle: 'Aarav Sharma · 7v7 · Court 2',
          badgeText: 'Pending',
          badgeBgColor: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFD97706),
          category: 'MATCH',
          icon: Icons.assignment_outlined,
          iconColor: const Color(0xFFEA580C),
          iconBgLight: const Color(0xFFFFEDD5),
          iconBgDark: const Color(0xFF3B2509),
          dateTime: DateTime(today.year, today.month, today.day, 10, 42),
          isRead: false,
        ),
        PlayerNotificationItem(
          id: 'mock_2',
          title: 'Match approved',
          subtitle: 'Friday Night Football · 8 players joined',
          badgeText: 'Approved',
          badgeBgColor: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF16A34A),
          category: 'MATCH',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgLight: const Color(0xFFDCFCE7),
          iconBgDark: const Color(0xFF0F331A),
          dateTime: DateTime(today.year, today.month, today.day, 9, 16),
          isRead: true,
        ),
        PlayerNotificationItem(
          id: 'mock_3',
          title: 'Payment received',
          subtitle: '₹250 received from Rahul Verma',
          badgeText: null,
          category: 'PAYMENT',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF059669),
          iconBgLight: const Color(0xFFD1FAE5),
          iconBgDark: const Color(0xFF0C382A),
          dateTime: DateTime(today.year, today.month, today.day, 8, 27),
          isRead: false,
        ),
        PlayerNotificationItem(
          id: 'mock_4',
          title: 'Match cancellation requested',
          subtitle: 'Sunday League · Refund pending',
          badgeText: 'Refund',
          badgeBgColor: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFDC2626),
          category: 'REFUND',
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFDC2626),
          iconBgLight: const Color(0xFFFEE2E2),
          iconBgDark: const Color(0xFF3D1515),
          dateTime:
              DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 18),
          isRead: true,
        ),
        PlayerNotificationItem(
          id: 'mock_5',
          title: 'Match completed',
          subtitle: 'Score submitted · 3-2',
          badgeText: null,
          category: 'MATCH',
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgLight: const Color(0xFFDBEAFE),
          iconBgDark: const Color(0xFF132B4A),
          dateTime:
              DateTime(yesterday.year, yesterday.month, yesterday.day, 12, 31),
          isRead: true,
        ),
        PlayerNotificationItem(
          id: 'mock_6',
          title: 'New player joined',
          subtitle: 'Rohan Patel joined your match',
          badgeText: null,
          category: 'PLAYER',
          icon: Icons.person_add_alt_1_rounded,
          iconColor: const Color(0xFF9333EA),
          iconBgLight: const Color(0xFFF3E8FF),
          iconBgDark: const Color(0xFF2C1542),
          dateTime:
              DateTime(yesterday.year, yesterday.month, yesterday.day, 11, 5),
          isRead: true,
        ),
        PlayerNotificationItem(
          id: 'mock_7',
          title: '5 players joined your match',
          subtitle: 'Weekend Football · Court 1',
          badgeText: null,
          category: 'PLAYER',
          icon: Icons.groups_rounded,
          iconColor: const Color(0xFF15803D),
          iconBgLight: const Color(0xFFDCFCE7),
          iconBgDark: const Color(0xFF0F331A),
          dateTime: DateTime(
              twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 20, 49),
          isRead: true,
        ),
      ]);
    }

    _localItems.assignAll(items);
  }

  PlayerNotificationItem _mapModelToPlayerItem(
      NotificationModel model, DateTime parsedDt) {
    final type = model.type.toUpperCase();
    String category = 'SYSTEM';
    IconData icon = Icons.notifications_none_rounded;
    Color iconColor = AppColors.primary;
    Color iconBgLight = const Color(0xFFDCFCE7);
    Color iconBgDark = const Color(0xFF0F331A);
    String? badgeText;
    Color? badgeBgColor;
    Color? badgeTextColor;

    if (type.contains('PAYMENT') || type.contains('WALLET')) {
      category = 'PAYMENT';
      icon = Icons.account_balance_wallet_rounded;
      iconColor = const Color(0xFF059669);
      iconBgLight = const Color(0xFFD1FAE5);
      iconBgDark = const Color(0xFF0C382A);
    } else if (type.contains('REFUND')) {
      category = 'REFUND';
      icon = Icons.cancel_outlined;
      iconColor = const Color(0xFFDC2626);
      iconBgLight = const Color(0xFFFEE2E2);
      iconBgDark = const Color(0xFF3D1515);
      badgeText = 'Refund';
      badgeBgColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
    } else if (type.contains('APPROVED')) {
      category = 'MATCH';
      icon = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF16A34A);
      iconBgLight = const Color(0xFFDCFCE7);
      iconBgDark = const Color(0xFF0F331A);
      badgeText = 'Approved';
      badgeBgColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    } else if (type.contains('PENDING')) {
      category = 'MATCH';
      icon = Icons.assignment_outlined;
      iconColor = const Color(0xFFEA580C);
      iconBgLight = const Color(0xFFFFEDD5);
      iconBgDark = const Color(0xFF3B2509);
      badgeText = 'Pending';
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
    } else if (type.contains('COMPLETED')) {
      category = 'MATCH';
      icon = Icons.emoji_events_rounded;
      iconColor = const Color(0xFF2563EB);
      iconBgLight = const Color(0xFFDBEAFE);
      iconBgDark = const Color(0xFF132B4A);
    } else if (type.contains('JOIN') || type.contains('PLAYER')) {
      category = 'PLAYER';
      icon = Icons.person_add_alt_1_rounded;
      iconColor = const Color(0xFF9333EA);
      iconBgLight = const Color(0xFFF3E8FF);
      iconBgDark = const Color(0xFF2C1542);
    } else if (type.contains('MATCH')) {
      category = 'MATCH';
      icon = Icons.sports_soccer_rounded;
      iconColor = AppColors.primary;
      iconBgLight = const Color(0xFFDCFCE7);
      iconBgDark = const Color(0xFF0F331A);
    }

    return PlayerNotificationItem(
      id: model.id,
      title: AppDateUtils.sanitizeNotificationText(model.title),
      subtitle: AppDateUtils.sanitizeNotificationText(model.body),
      badgeText: badgeText,
      badgeBgColor: badgeBgColor,
      badgeTextColor: badgeTextColor,
      category: category,
      icon: icon,
      iconColor: iconColor,
      iconBgLight: iconBgLight,
      iconBgDark: iconBgDark,
      dateTime: parsedDt,
      isRead: model.isRead,
      data: model.data,
    );
  }

  List<PlayerNotificationItem> get _filteredList {
    final query = _searchQuery.value.trim().toLowerCase();
    final activity = _selectedActivity.value;
    final dateFilter = _selectedDateFilter.value;
    final unreadOnly = _showUnreadOnly.value;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return _localItems.where((item) {
      if (unreadOnly && item.isRead) return false;

      if (query.isNotEmpty) {
        final title = item.title.toLowerCase();
        final sub = item.subtitle.toLowerCase();
        final badge = (item.badgeText ?? '').toLowerCase();
        if (!title.contains(query) &&
            !sub.contains(query) &&
            !badge.contains(query)) {
          return false;
        }
      }

      if (activity != 'All activity') {
        if (activity == 'Matches' && item.category != 'MATCH') return false;
        if (activity == 'Payments' && item.category != 'PAYMENT') return false;
        if (activity == 'Players' && item.category != 'PLAYER') return false;
        if (activity == 'Refunds' && item.category != 'REFUND') return false;
      }

      final itemDate =
          DateTime(item.dateTime.year, item.dateTime.month, item.dateTime.day);

      if (dateFilter == 'Date: Today') {
        if (itemDate != today) return false;
      } else if (dateFilter == 'Date: Yesterday') {
        if (itemDate != yesterday) return false;
      } else if (dateFilter == 'Date: Last 7 days') {
        if (now.difference(item.dateTime).inDays > 7) return false;
      } else if (dateFilter.startsWith('Date: ') &&
          _customDate.value != null &&
          dateFilter != 'Date: All time') {
        final custom = DateTime(_customDate.value!.year,
            _customDate.value!.month, _customDate.value!.day);
        if (itemDate != custom) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<PlayerNotificationItem>> _groupByDate(
      List<PlayerNotificationItem> items) {
    final Map<String, List<PlayerNotificationItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final sorted = List<PlayerNotificationItem>.from(items)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (final item in sorted) {
      final itemDate =
          DateTime(item.dateTime.year, item.dateTime.month, item.dateTime.day);

      String header;
      if (itemDate == today) {
        header = 'Today · ${DateFormat('d MMM yyyy').format(item.dateTime)}';
      } else if (itemDate == yesterday) {
        header =
            'Yesterday · ${DateFormat('d MMM yyyy').format(item.dateTime)}';
      } else {
        header = DateFormat('d MMM yyyy').format(item.dateTime);
      }

      groups.putIfAbsent(header, () => []).add(item);
    }

    return groups;
  }

  void _markItemAsRead(PlayerNotificationItem item) {
    final idx = _localItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _localItems[idx] = item.copyWith(isRead: true);
    }

    if (!item.id.startsWith('mock_')) {
      final raw =
          _controller.notifications.firstWhereOrNull((n) => n.id == item.id);
      if (raw != null) {
        _controller.markAsReadAndNavigate(raw);
      }
    }
  }

  void _markAllAsRead() {
    for (int i = 0; i < _localItems.length; i++) {
      _localItems[i] = _localItems[i].copyWith(isRead: true);
    }
    _controller.markAllRead();
    Get.snackbar(
      'Marked as Read',
      'All notifications marked as read',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showDeleteConfirmation(BuildContext context, List<String> visibleIds) {
    final count = _controller.selectedIds.length;
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
              _controller.deleteSelectedNotifications();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
      BuildContext context, List<String> visibleIds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
        if (_controller.isSelectionMode) {
          final selectedCount = _controller.selectedIds.length;
          final isAllSelected =
              _controller.selectedIds.containsAll(visibleIds) &&
                  visibleIds.isNotEmpty;

          return AppBar(
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _controller.clearSelection(),
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
                onPressed: () => _controller.selectAll(visibleIds),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            Obx(() {
              final unreadCount = _localItems.where((i) => !i.isRead).length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                      size: 24,
                    ),
                    tooltip: 'Notification Options',
                    onPressed: _showNotificationOptionsMenu,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 13,
                      right: 13,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleIds = _filteredList.map((i) => i.id).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildSelectionAppBar(context, visibleIds),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => _searchQuery.value = val,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search notifications',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMutedDark
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.textMutedDark
                                : const Color(0xFF94A3B8),
                          ),
                          suffixIcon: Obx(() {
                            if (_searchQuery.value.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            );
                          }),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _showComprehensiveFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkInputBg : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Obx(() => _buildDropdownPill(
                        label: _selectedActivity.value,
                        onTap: _showActivityPickerMenu,
                        isDark: isDark,
                      )),
                  const SizedBox(width: 10),
                  Obx(() => _buildDropdownPill(
                        label: _selectedDateFilter.value,
                        onTap: _showDateFilterPickerMenu,
                        isDark: isDark,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final filtered = _filteredList;
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await _controller.fetchNotifications(isRefresh: true);
                      _loadAndPrepareItems();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: const EmptyStateWidget(
                            title: 'No Notifications Found',
                            subtitle:
                                'No notifications match your current search or selected filters.',
                            icon: Icons.notifications_off_outlined,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDate(filtered);
                final groupKeys = grouped.keys.toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    await _controller.fetchNotifications(isRefresh: true);
                    _loadAndPrepareItems();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groupKeys.length,
                    itemBuilder: (context, gIndex) {
                      final header = groupKeys[gIndex];
                      final itemsInGroup = grouped[header]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 14,
                              bottom: 10,
                              left: 2,
                            ),
                            child: Text(
                              header,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          ...itemsInGroup.map(
                            (item) => _buildNotificationCard(
                              context,
                              item,
                              isDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    PlayerNotificationItem item,
    bool isDark,
  ) {
    return Obx(() {
      final isSelected = _controller.selectedIds.contains(item.id);
      final isSelectionMode = _controller.isSelectionMode;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isSelectionMode) {
                  _controller.toggleSelection(item.id);
                } else {
                  _markItemAsRead(item);
                  _showNotificationDetailModal(item);
                }
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  _controller.toggleSelection(item.id);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? item.iconBgDark : item.iconBgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: item.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (item.badgeText != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.badgeBgColor ??
                                        const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      color: item.badgeTextColor ??
                                          const Color(0xFFD97706),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatItemTime(item.dateTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final isSelected =
                          _controller.selectedIds.contains(item.id);
                      final isSelectionMode = _controller.isSelectionMode;

                      if (isSelectionMode) {
                        return Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 20,
                        );
                      }
                      if (!item.isRead) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  String _formatItemTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (itemDate == today ||
        itemDate == today.subtract(const Duration(days: 1))) {
      return DateFormat('h:mm a').format(dt);
    } else {
      return DateFormat('d MMM, h:mm a').format(dt);
    }
  }

  void _showActivityPickerMenu() {
    final activities = [
      'All activity',
      'Matches',
      'Payments',
      'Players',
      'Refunds',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...activities.map(
              (act) => ListTile(
                title: Text(act),
                trailing: _selectedActivity.value == act
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  _selectedActivity.value = act;
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFilterPickerMenu() {
    final dateOptions = [
      'Date: All time',
      'Date: Today',
      'Date: Yesterday',
      'Date: Last 7 days',
      'Pick Custom Date...',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...dateOptions.map(
              (opt) => ListTile(
                title: Text(opt),
                trailing: _selectedDateFilter.value == opt
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Get.back();
                  if (opt == 'Pick Custom Date...') {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _customDate.value = picked;
                      _selectedDateFilter.value =
                          'Date: ${DateFormat('d MMM').format(picked)}';
                    }
                  } else {
                    _selectedDateFilter.value = opt;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComprehensiveFilterSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notification Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _selectedActivity.value = 'All activity';
                    _selectedDateFilter.value = 'Date: All time';
                    _showUnreadOnly.value = false;
                    _customDate.value = null;
                    Get.back();
                  },
                  child: const Text('Reset',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
            const Divider(),
            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Unread Only'),
                  subtitle: const Text('Display only unread alerts'),
                  value: _showUnreadOnly.value,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => _showUnreadOnly.value = val,
                )),
            const SizedBox(height: 10),
            const Text('Activity Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['All activity', 'Matches', 'Payments', 'Players', 'Refunds']
                      .map((act) => Obx(() {
                            final isSel = _selectedActivity.value == act;
                            return ChoiceChip(
                              label: Text(act),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : null,
                                fontSize: 12,
                              ),
                              onSelected: (_) => _selectedActivity.value = act,
                            );
                          }))
                      .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showNotificationOptionsMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.done_all_rounded, color: AppColors.primary),
              title: const Text('Mark all as read'),
              onTap: () {
                Get.back();
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Refresh notifications'),
              onTap: () {
                Get.back();
                _controller.fetchNotifications(isRefresh: true);
                _loadAndPrepareItems();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetailModal(PlayerNotificationItem item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.iconBgLight,
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppDateUtils.formatDateTime(item.dateTime),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (item.badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.badgeBgColor ?? Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: TextStyle(
                        color: item.badgeTextColor ?? Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef PlayerNotification = PlayerNotificationView;
