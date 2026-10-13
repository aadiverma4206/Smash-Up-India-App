import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import 'admin_audit_log_detail_view.dart';

class AdminAuditLogsView extends StatefulWidget {
  const AdminAuditLogsView({super.key});

  @override
  State<AdminAuditLogsView> createState() => _AdminAuditLogsViewState();
}

class _AdminAuditLogsViewState extends State<AdminAuditLogsView> {
  late final AdminController controller;
  final TextEditingController filterController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxString filterQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminController>();
    scrollController.addListener(_onScroll);
    controller.fetchAuditLogs();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 250) {
      controller.fetchAuditLogs(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    filterController.dispose();
    super.dispose();
  }

  /// Groups logs by Date String (Today, Yesterday, or Format 'd MMM yyyy')
  Map<String, List<AuditLogModel>> _groupLogsByDate(List<AuditLogModel> logs) {
    final Map<String, List<AuditLogModel>> grouped = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (final log in logs) {
      String dateHeader = 'Recent Activity';
      if (log.createdAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(log.createdAt);
          final logDateStr = DateFormat('yyyy-MM-dd').format(dt);
          if (logDateStr == todayStr) {
            dateHeader = 'Today';
          } else if (logDateStr == yesterdayStr) {
            dateHeader = 'Yesterday • ${DateFormat('d MMM yyyy').format(dt)}';
          } else {
            dateHeader = DateFormat('d MMM yyyy').format(dt);
          }
        } catch (_) {
          if (log.createdAt.length >= 10) {
            dateHeader = log.createdAt.substring(0, 10);
          }
        }
      }
      grouped.putIfAbsent(dateHeader, () => []).add(log);
    }
    return grouped;
  }

  String _formatTimeOnly(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      if (createdAt.length >= 16) {
        return createdAt.substring(11, 16);
      }
      return createdAt;
    }
  }

  Color _getCategoryBgColor(String action, bool isDark) {
    final act = action.toLowerCase();
    if (act.contains('approved') ||
        act.contains('success') ||
        act.contains('confirm')) {
      return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
    }
    if (act.contains('refund') ||
        act.contains('cancel') ||
        act.contains('suspend')) {
      return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
    }
    if (act.contains('join') || act.contains('user')) {
      return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
    }
    return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
  }

  Color _getCategoryIconColor(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') ||
        act.contains('success') ||
        act.contains('confirm')) {
      return const Color(0xFF00C853);
    }
    if (act.contains('refund') ||
        act.contains('cancel') ||
        act.contains('suspend')) {
      return const Color(0xFFE53935);
    }
    if (act.contains('join') || act.contains('user')) {
      return const Color(0xFF8E24AA);
    }
    return const Color(0xFF1E88E5);
  }

  IconData _getCategoryIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') || act.contains('confirm')) {
      return Icons.check_circle_outline_rounded;
    }
    if (act.contains('refund') || act.contains('payment')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (act.contains('cancel') || act.contains('suspend')) {
      return Icons.cancel_outlined;
    }
    if (act.contains('score') || act.contains('match')) {
      return Icons.emoji_events_outlined;
    }
    if (act.contains('join') || act.contains('user')) {
      return Icons.person_add_alt_1_rounded;
    }
    return Icons.security_rounded;
  }

  String? _getStatusTagLabel(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved')) return 'Approved';
    if (act.contains('refund')) return 'Refund';
    if (act.contains('success')) return 'Success';
    if (act.contains('suspend')) return 'Suspended';
    if (act.contains('cancel')) return 'Cancelled';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchAuditLogs(),
            tooltip: 'Refresh Audit Logs',
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop = deviceType == DeviceType.tablet ||
              deviceType == DeviceType.desktop;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              children: [
                // Filter Search Bar
                AppTextField(
                  label: '',
                  hint: 'Filter Audit Logs by Action or Details...',
                  controller: filterController,
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Colors.grey, size: 20),
                    onPressed: () {
                      filterController.clear();
                      filterQuery.value = '';
                    },
                  ),
                  onChanged: (val) {
                    filterQuery.value = val.trim().toLowerCase();
                  },
                ),
                const SizedBox(height: 12),

                // Audit Logs Content List
                Expanded(
                  child: Obx(() {
                    // 1. Shimmer Loading State
                    if (controller.isLoadingLogs.value &&
                        controller.auditLogs.isEmpty) {
                      return _buildShimmerView(context, deviceType);
                    }

                    // Filter logs locally
                    final query = filterQuery.value;
                    final filteredLogs = controller.auditLogs.where((log) {
                      if (query.isEmpty) return true;
                      final actionMatch =
                          log.action.toLowerCase().contains(query);
                      final detailsMatch =
                          (log.details ?? '').toLowerCase().contains(query);
                      final userMatch =
                          (log.userId ?? '').toLowerCase().contains(query);
                      return actionMatch || detailsMatch || userMatch;
                    }).toList();

                    // 2. Empty State
                    if (filteredLogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security_rounded,
                              size: 48,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No audit logs found.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                filterController.clear();
                                filterQuery.value = '';
                                controller.fetchAuditLogs();
                              },
                              child: const Text('Refresh & Clear Filter'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group logs by Date Header
                    final groupedLogs = _groupLogsByDate(filteredLogs);

                    return RefreshIndicator(
                      onRefresh: () async => controller.fetchAuditLogs(),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: groupedLogs.length +
                            (controller.hasMoreAuditLogs.value ? 1 : 0),
                        itemBuilder: (context, sectionIndex) {
                          if (sectionIndex == groupedLogs.length) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: controller.isLoadingMoreAuditLogs.value
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary)
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final dateHeader =
                              groupedLogs.keys.elementAt(sectionIndex);
                          final logsForDate = groupedLogs[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 14.0, bottom: 8.0, left: 4.0),
                                child: Text(
                                  dateHeader,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),

                              // Cards List for this Date
                              if (isTabletOrDesktop)
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        deviceType == DeviceType.desktop
                                            ? 3
                                            : 2,
                                    childAspectRatio: 3.0,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: logsForDate.length,
                                  itemBuilder: (context, index) {
                                    return _buildAuditLogCard(
                                        context, logsForDate[index]);
                                  },
                                )
                              else
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: logsForDate.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _buildAuditLogCard(
                                        context, logsForDate[index]);
                                  },
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
          );
        },
      ),
    );
  }

  /// Design matching Screenshot UI: Circular Icon, Title, Time, Subtitle, Status Tag
  Widget _buildAuditLogCard(BuildContext context, AuditLogModel log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getCategoryBgColor(log.action, isDark);
    final iconColor = _getCategoryIconColor(log.action);
    final iconData = _getCategoryIcon(log.action);
    final statusTag = _getStatusTagLabel(log.action);
    final timeStr = _formatTimeOnly(log.createdAt);

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigates to dedicated Audit Log Detail Page
          Get.to(() => AdminAuditLogDetailView(auditLog: log));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Category Icon Badge
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

              // Action Title, Subtitle, Status Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title & Time Top Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            log.action,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
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
                    const SizedBox(height: 3),

                    // Subtitle Details
                    if (log.details != null && log.details!.isNotEmpty) ...[
                      Text(
                        log.details!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                    ],

                    // Status Tag Badge if available
                    if (statusTag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusTag,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
          childAspectRatio: 3.0,
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
                    width: 160, height: 11, borderRadius: 4, enable3D: true),
                const SizedBox(height: 5),
                const AppShimmer(
                    width: 55, height: 12, borderRadius: 4, enable3D: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
