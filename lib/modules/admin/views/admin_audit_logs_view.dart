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

enum AuditLogCategory {
  userCreated,
  matchCreated,
  matchCancelled,
  matchCompleted,
  unknown,
}

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
  final RxString selectedCategoryFilter = 'ALL'.obs;

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

  AuditLogCategory _getCategory(AuditLogModel log) {
    final action = log.action.toUpperCase();
    final details = (log.details ?? '').toLowerCase();

    // 1. User Account Created / Managed
    if (action.contains('USER') ||
        action.contains('REGISTER') ||
        action.contains('MANAGER') ||
        action.contains('SUSPEND') ||
        details.contains('user') ||
        details.contains('manager') ||
        details.contains('account created') ||
        details.contains('registered')) {
      return AuditLogCategory.userCreated;
    }

    // 2. Match Created
    if (action.contains('MATCH_CREATED') ||
        action.contains('GAME_CREATED') ||
        action.contains('SLOT_CREATED') ||
        (action.contains('MATCH') && action.contains('CREATE')) ||
        (action.contains('GAME') && action.contains('CREATE')) ||
        details.contains('match created') ||
        details.contains('game created')) {
      return AuditLogCategory.matchCreated;
    }

    // 3. Match Cancelled & Payment Refunded
    if (action.contains('CANCEL') ||
        action.contains('REFUND') ||
        details.contains('cancel') ||
        details.contains('refund')) {
      return AuditLogCategory.matchCancelled;
    }

    // 4. Match Completed & Score Resolved
    if (action.contains('COMPLETE') ||
        action.contains('DISPUTE') ||
        action.contains('SCORE') ||
        details.contains('completed') ||
        details.contains('final score')) {
      return AuditLogCategory.matchCompleted;
    }

    return AuditLogCategory.unknown;
  }

  bool _isAllowedAuditLog(AuditLogModel log) {
    return _getCategory(log) != AuditLogCategory.unknown;
  }

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

  Color _getCategoryBgColor(AuditLogCategory cat, bool isDark) {
    switch (cat) {
      case AuditLogCategory.userCreated:
        return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
      case AuditLogCategory.matchCreated:
        return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
      case AuditLogCategory.matchCancelled:
        return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
      case AuditLogCategory.matchCompleted:
        return isDark ? const Color(0xFF2E2412) : const Color(0xFFFEF8E8);
      case AuditLogCategory.unknown:
        return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
    }
  }

  Color _getCategoryIconColor(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.userCreated:
        return const Color(0xFF8E24AA);
      case AuditLogCategory.matchCreated:
        return const Color(0xFF00C853);
      case AuditLogCategory.matchCancelled:
        return const Color(0xFFE53935);
      case AuditLogCategory.matchCompleted:
        return const Color(0xFFFFB300);
      case AuditLogCategory.unknown:
        return const Color(0xFF1E88E5);
    }
  }

  IconData _getCategoryIcon(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.userCreated:
        return Icons.person_add_rounded;
      case AuditLogCategory.matchCreated:
        return Icons.add_circle_outline_rounded;
      case AuditLogCategory.matchCancelled:
        return Icons.cancel_outlined;
      case AuditLogCategory.matchCompleted:
        return Icons.emoji_events_rounded;
      case AuditLogCategory.unknown:
        return Icons.security_rounded;
    }
  }

  String _getCategoryBadgeLabel(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.userCreated:
        return 'USER / ACCOUNT';
      case AuditLogCategory.matchCreated:
        return 'MATCH CREATED';
      case AuditLogCategory.matchCancelled:
        return 'CANCELLED & REFUNDED';
      case AuditLogCategory.matchCompleted:
        return 'MATCH COMPLETED';
      case AuditLogCategory.unknown:
        return 'SYSTEM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.sageGreenAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'System Audit Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
            onPressed: () => controller.fetchAuditLogs(),
            tooltip: 'Refresh Audit Logs',
          ),
          const SizedBox(width: 4),
        ],
      ),
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
                      hint: 'Filter Audit Logs by Action or Details...',
                      controller: filterController,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 20),
                      suffixIcon: Obx(() {
                        if (filterQuery.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            filterController.clear();
                            filterQuery.value = '';
                          },
                        );
                      }),
                      onChanged: (val) {
                        filterQuery.value = val.trim().toLowerCase();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryFilterChips(context),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoadingLogs.value &&
                            controller.auditLogs.isEmpty) {
                          return _buildShimmerView(context, deviceType);
                        }

                        final query = filterQuery.value;
                        final categoryFilter = selectedCategoryFilter.value;

                        // Filter ONLY allowed 4 audit log categories
                        final allowedLogs = controller.auditLogs
                            .where(_isAllowedAuditLog)
                            .toList();

                        final filteredLogs = allowedLogs.where((log) {
                          final cat = _getCategory(log);
                          if (categoryFilter != 'ALL') {
                            if (categoryFilter == 'USER' &&
                                cat != AuditLogCategory.userCreated) {
                              return false;
                            }
                            if (categoryFilter == 'CREATED' &&
                                cat != AuditLogCategory.matchCreated) {
                              return false;
                            }
                            if (categoryFilter == 'CANCELLED' &&
                                cat != AuditLogCategory.matchCancelled) {
                              return false;
                            }
                            if (categoryFilter == 'COMPLETED' &&
                                cat != AuditLogCategory.matchCompleted) {
                              return false;
                            }
                          }

                          if (query.isNotEmpty) {
                            final actionMatch =
                                log.action.toLowerCase().contains(query);
                            final detailsMatch = (log.details ?? '')
                                .toLowerCase()
                                .contains(query);
                            final userMatch = (log.userId ?? '')
                                .toLowerCase()
                                .contains(query);
                            return actionMatch || detailsMatch || userMatch;
                          }
                          return true;
                        }).toList();

                        if (filteredLogs.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
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
                                      Icons.security_rounded,
                                      size: 48,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No audit logs found',
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
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      filterController.clear();
                                      filterQuery.value = '';
                                      selectedCategoryFilter.value = 'ALL';
                                      controller.fetchAuditLogs();
                                    },
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label:
                                        const Text('Reset Filters & Refresh'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final groupedLogs = _groupLogsByDate(filteredLogs);

                        return RefreshIndicator(
                          onRefresh: () async => controller.fetchAuditLogs(),
                          child: ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            itemCount: groupedLogs.length +
                                (controller.hasMoreAuditLogs.value ? 1 : 0),
                            itemBuilder: (context, sectionIndex) {
                              if (sectionIndex == groupedLogs.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child:
                                        controller.isLoadingMoreAuditLogs.value
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
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth > 850) {
                                        return GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          gridDelegate:
                                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 560,
                                            mainAxisExtent: 130,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: logsForDate.length,
                                          itemBuilder: (context, index) {
                                            return _buildAuditLogCard(
                                                context, logsForDate[index]);
                                          },
                                        );
                                      }
                                      return ListView.separated(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: logsForDate.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          return _buildAuditLogCard(
                                              context, logsForDate[index]);
                                        },
                                      );
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final allowed = controller.auditLogs.where(_isAllowedAuditLog).toList();

      final countAll = allowed.length;
      final countUser = allowed
          .where((l) => _getCategory(l) == AuditLogCategory.userCreated)
          .length;
      final countCreated = allowed
          .where((l) => _getCategory(l) == AuditLogCategory.matchCreated)
          .length;
      final countCancelled = allowed
          .where((l) => _getCategory(l) == AuditLogCategory.matchCancelled)
          .length;
      final countCompleted = allowed
          .where((l) => _getCategory(l) == AuditLogCategory.matchCompleted)
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

  Widget _buildAuditLogCard(BuildContext context, AuditLogModel log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _getCategory(log);
    final bgColor = _getCategoryBgColor(category, isDark);
    final iconColor = _getCategoryIconColor(category);
    final iconData = _getCategoryIcon(category);
    final badgeLabel = _getCategoryBadgeLabel(category);
    final timeStr = _formatTimeOnly(log.createdAt);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => AdminAuditLogDetailView(auditLog: log));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
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
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
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
                      log.action,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (log.details != null && log.details!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        log.details!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
