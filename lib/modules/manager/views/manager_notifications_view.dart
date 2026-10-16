import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../repositories/manager_repository.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/slot_request_model.dart';
import '../../../data/models/notification_model.dart';

/// Unified representation for real manager notification & action cards
class ManagerAlertItem {
  final String id;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final String category; // 'MATCH', 'SLOT', 'PAYMENT', 'REFUND', 'SYSTEM'
  final IconData icon;
  final Color iconColor;
  final Color iconBgLight;
  final Color iconBgDark;
  final DateTime dateTime;
  final bool isUnread;
  final bool isPendingAction;
  final GameModel? originalGame;
  final SlotRequestModel? originalSlot;

  ManagerAlertItem({
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
    required this.isUnread,
    this.isPendingAction = false,
    this.originalGame,
    this.originalSlot,
  });
}

class ManagerNotificationsView extends StatefulWidget {
  const ManagerNotificationsView({super.key});

  @override
  State<ManagerNotificationsView> createState() =>
      _ManagerNotificationsViewState();
}

class _ManagerNotificationsViewState extends State<ManagerNotificationsView> {
  late final ManagerDashboardController dashboardController;
  final ManagerRepository repository = Get.find<ManagerRepository>();
  final DatabaseService dbService = Get.find<DatabaseService>();

  final TextEditingController _searchController = TextEditingController();

  final RxString _searchQuery = ''.obs;
  final RxString _activeCategoryFilter = 'All activity'.obs;
  final RxBool _showUnreadOnly = false.obs;
  final RxBool _isOfflineMode = false.obs;
  final RxBool _isLoadingNotifications = false.obs;

  final RxList<NotificationModel> _serverNotifications =
      <NotificationModel>[].obs;

  @override
  void initState() {
    super.initState();
    dashboardController = Get.find<ManagerDashboardController>();
    _fetchAndSyncNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Syncs notifications with backend when online & loads/upserts to SQLite local storage.
  /// Prunes records older than 3 days (72 hours).
  Future<void> _fetchAndSyncNotifications() async {
    _isLoadingNotifications.value = true;
    final userId = Get.find<AuthService>().currentUser.value?.id ?? '';

    try {
      // 1. Load pending dashboard actions
      await dashboardController.loadManagerData();

      // 2. Attempt online fetch from server
      final List<NotificationModel> remoteNotifs =
          await repository.getNotifications(page: 1, limit: 100);
      _isOfflineMode.value = false;

      // Upsert into SQLite & prune records older than 3 days
      if (userId.isNotEmpty && remoteNotifs.isNotEmpty) {
        final List<Map<String, dynamic>> jsonList =
            remoteNotifs.map((n) => n.toJson()).toList();
        await dbService.upsertLocalNotifications(userId, jsonList);
      }

      _serverNotifications.assignAll(remoteNotifs);
    } catch (e) {
      AppLogger.warning(
          'Network error fetching manager notifications, falling back to local SQLite cache: $e');
      _isOfflineMode.value = true;

      // Fallback to SQLite local storage & prune >3 days old records
      if (userId.isNotEmpty) {
        final localRows = await dbService.getLocalNotifications(userId);
        final cachedNotifs =
            localRows.map((r) => NotificationModel.fromJson(r)).toList();
        _serverNotifications.assignAll(cachedNotifs);
      }
    } finally {
      _isLoadingNotifications.value = false;
    }
  }

  /// Builds deduplicated alert items combining real database notifications & pending dashboard actions
  List<ManagerAlertItem> _buildAlertItems() {
    final now = DateTime.now();
    final itemsMap = <String, ManagerAlertItem>{};

    // 1. REAL Pending Games awaiting Manager Approval
    for (final game in dashboardController.pendingPlayerGames) {
      final parsedDate =
          AppDateUtils.parseMatchDateTime(game.matchDate, game.startTime) ??
              now;
      final key = 'pending_game_${game.id}';
      itemsMap[key] = ManagerAlertItem(
        id: key,
        title: 'New match awaiting approval',
        subtitle: '${game.title} · ${game.format} · ${game.courtName}',
        badgeText: 'Pending',
        badgeBgColor: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFFD97706),
        category: 'MATCH',
        icon: Icons.assignment_outlined,
        iconColor: const Color(0xFFEA580C),
        iconBgLight: const Color(0xFFFFEDD5),
        iconBgDark: const Color(0xFF3B2509),
        dateTime: parsedDate,
        isUnread: true,
        isPendingAction: true,
        originalGame: game,
      );
    }

    // 2. REAL Pending Player Slot Requests
    for (final slot in dashboardController.pendingRequests) {
      final parsedDate = AppDateUtils.parseDate(slot.createdAt) ?? now;
      final key = 'pending_slot_${slot.id}';
      itemsMap[key] = ManagerAlertItem(
        id: key,
        title: 'New player joined match',
        subtitle:
            '${slot.playerName ?? "Player"} joined ${slot.gameTitle ?? "Court Match"} (${slot.courtName ?? "Court 1"})',
        badgeText: 'Pending',
        badgeBgColor: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFFD97706),
        category: 'SLOT',
        icon: Icons.person_add_alt_1_rounded,
        iconColor: const Color(0xFF9333EA),
        iconBgLight: const Color(0xFFF3E8FF),
        iconBgDark: const Color(0xFF2C1542),
        dateTime: parsedDate,
        isUnread: true,
        isPendingAction: true,
        originalSlot: slot,
      );
    }

    // 3. REAL Notifications from Database (or SQLite Cache)
    for (final notif in _serverNotifications) {
      final parsedDate = AppDateUtils.parseDate(notif.createdAt) ?? now;
      final typeUpper = notif.type.toUpperCase();

      IconData icon = Icons.notifications_active_rounded;
      Color iconColor = AppColors.primary;
      Color iconBgLight = AppColors.primary.withValues(alpha: 0.15);
      Color iconBgDark = const Color(0xFF0F331A);
      String category = 'SYSTEM';
      String? badgeText;
      Color? badgeBgColor;
      Color? badgeTextColor;

      if (typeUpper.contains('PAYMENT') || typeUpper.contains('WALLET')) {
        category = 'PAYMENT';
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF059669);
        iconBgLight = const Color(0xFFD1FAE5);
        iconBgDark = const Color(0xFF0C382A);
      } else if (typeUpper.contains('REFUND') || typeUpper.contains('CANCEL')) {
        category = 'REFUND';
        icon = Icons.cancel_outlined;
        iconColor = const Color(0xFFDC2626);
        iconBgLight = const Color(0xFFFEE2E2);
        iconBgDark = const Color(0xFF3B0D0D);
        badgeText = 'Refund';
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFDC2626);
      } else if (typeUpper.contains('MATCH') || typeUpper.contains('SLOT')) {
        category = 'MATCH';
        icon = Icons.sports_soccer_rounded;
        iconColor = AppColors.primary;
        iconBgLight = AppColors.primary.withValues(alpha: 0.15);
        iconBgDark = const Color(0xFF0F331A);
      }

      itemsMap[notif.id] = ManagerAlertItem(
        id: notif.id,
        title: notif.title,
        subtitle: notif.body,
        badgeText: badgeText,
        badgeBgColor: badgeBgColor,
        badgeTextColor: badgeTextColor,
        category: category,
        icon: icon,
        iconColor: iconColor,
        iconBgLight: iconBgLight,
        iconBgDark: iconBgDark,
        dateTime: parsedDate,
        isUnread: !notif.isRead,
      );
    }

    final resultList = itemsMap.values.toList();
    resultList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return resultList;
  }

  /// Filters items based on search query, category, unread toggle, and date
  List<ManagerAlertItem> _getFilteredItems(List<ManagerAlertItem> allItems) {
    final query = _searchQuery.value.trim().toLowerCase();
    final category = _activeCategoryFilter.value;
    final unreadOnly = _showUnreadOnly.value;

    return allItems.where((item) {
      if (unreadOnly && !item.isUnread) return false;

      if (category == 'Match Approvals' && item.category != 'MATCH') {
        return false;
      }
      if (category == 'Slot Requests' && item.category != 'SLOT') {
        return false;
      }
      if (category == 'Payments & Refunds' &&
          item.category != 'PAYMENT' &&
          item.category != 'REFUND') {
        return false;
      }

      if (query.isNotEmpty) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final subMatch = item.subtitle.toLowerCase().contains(query);
        if (!titleMatch && !subMatch) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_rounded),
            tooltip: 'Mark All Read',
            onPressed: () async {
              final userId =
                  Get.find<AuthService>().currentUser.value?.id ?? '';
              if (userId.isNotEmpty) {
                await repository.markAllNotificationsRead();
                await dbService.markAllLocalNotificationsRead(userId);
                _fetchAndSyncNotifications();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Notifications',
            onPressed: _fetchAndSyncNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline Mode / 3-Day Local Cache Banner
            Obx(() {
              if (!_isOfflineMode.value) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.withValues(alpha: 0.15),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off_rounded,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Mode · Showing 3-Day Cached Notifications',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Top Search & Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchQuery.value = val,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search notifications by keyword...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All activity',
                        'Match Approvals',
                        'Slot Requests',
                        'Payments & Refunds',
                      ].map((cat) {
                        return Obx(() {
                          final isSelected = _activeCategoryFilter.value == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textPrimaryDark
                                            : Colors.black87),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  )),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: Theme.of(context).cardColor,
                              onSelected: (_) =>
                                  _activeCategoryFilter.value = cat,
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications Feed Body
            Expanded(
              child: Obx(() {
                if (_isLoadingNotifications.value &&
                    _serverNotifications.isEmpty) {
                  return const AppLoader(
                      message: 'Syncing manager notifications...');
                }

                final allAlerts = _buildAlertItems();
                final filtered = _getFilteredItems(allAlerts);

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Notifications Found',
                    subtitle:
                        'No notifications or pending alerts match your current filter.',
                    icon: Icons.notifications_none_rounded,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _fetchAndSyncNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildAlertCard(context, item);
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

  Widget _buildAlertCard(BuildContext context, ManagerAlertItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedTime = AppDateUtils.formatRelativeTime(item.dateTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isUnread
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE)),
          width: item.isUnread ? 1.2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? item.iconBgDark : item.iconBgLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
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
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.badgeText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.badgeBgColor ?? AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: TextStyle(
                                color: item.badgeTextColor ?? Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade500,
                ),
              ),
              if (item.isPendingAction) ...[
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _handleRejectAction(item),
                      child: const Text('Reject',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _handleApproveAction(item),
                      child: const Text('Approve',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _handleApproveAction(ManagerAlertItem item) async {
    if (item.originalGame != null) {
      await dashboardController.approvePlayerGame(item.originalGame!.id);
      _fetchAndSyncNotifications();
    } else if (item.originalSlot != null) {
      await dashboardController.approveSlotRequest(item.originalSlot!.id);
      _fetchAndSyncNotifications();
    }
  }

  void _handleRejectAction(ManagerAlertItem item) async {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Get.back();
              if (item.originalGame != null) {
                await dashboardController.rejectPlayerGame(
                    item.originalGame!.id, reasonController.text.trim());
              } else if (item.originalSlot != null) {
                await dashboardController.rejectSlotRequest(
                    item.originalSlot!.id, reasonController.text.trim());
              }
              _fetchAndSyncNotifications();
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
