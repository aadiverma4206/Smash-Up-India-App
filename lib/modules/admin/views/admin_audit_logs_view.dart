import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import 'admin_audit_log_detail_view.dart';

enum AuditLogCategory {
  user,
  match,
  refund,
  system,
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
    final details = (log.details ?? '').toUpperCase();

    if (action.contains('CANCEL') ||
        action.contains('REFUND') ||
        details.contains('CANCEL') ||
        details.contains('REFUND')) {
      return AuditLogCategory.refund;
    }

    if (action.contains('USER') ||
        action.contains('REGISTER') ||
        action.contains('MANAGER') ||
        action.contains('ADMIN') ||
        action.contains('SUSPEND') ||
        action.contains('REACTIVATE') ||
        details.contains('USER') ||
        details.contains('MANAGER') ||
        details.contains('ACCOUNT')) {
      return AuditLogCategory.user;
    }

    if (action.contains('MATCH') ||
        action.contains('GAME') ||
        action.contains('SLOT') ||
        action.contains('SCORE') ||
        details.contains('MATCH') ||
        details.contains('GAME')) {
      return AuditLogCategory.match;
    }

    return AuditLogCategory.system;
  }

  String _getHumanReadableTitle(String rawAction) {
    final act = rawAction.trim().toUpperCase();
    switch (act) {
      case 'MANAGER_ACCOUNT_CREATED':
        return 'Manager Account Created';
      case 'ADMIN_ACCOUNT_CREATED':
        return 'Admin Account Created';
      case 'USER_SUSPENDED':
        return 'User Account Suspended';
      case 'USER_REACTIVATED':
        return 'User Account Reactivated';
      case 'MATCH_CREATED':
      case 'GAME_CREATED':
        return 'New Match Created';
      case 'MATCH_CANCELLED':
      case 'PITCH_BOOKING_CANCELLED':
        return 'Match Cancelled & Refunded';
      case 'MATCH_COMPLETED':
        return 'Match Completed';
      case 'CLUB_VENUE_APPROVED':
        return 'Turf Venue Approved';
      case 'MATCH_DISPUTE_RESOLVED':
        return 'Match Dispute Resolved';
      case 'PAYMENT_REFUNDED':
      case 'REFUND_ISSUED':
        return 'Payment Refund Issued';
      default:
        return rawAction
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
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
        final dt = AppDateUtils.parseDateTime(log.createdAt);
        if (dt != null) {
          final logDateStr = DateFormat('yyyy-MM-dd').format(dt);
          if (logDateStr == todayStr) {
            dateHeader = 'Today';
          } else if (logDateStr == yesterdayStr) {
            dateHeader = 'Yesterday';
          } else {
            dateHeader = DateFormat('dd MMMM yyyy').format(dt);
          }
        }
      }
      grouped.putIfAbsent(dateHeader, () => []).add(log);
    }
    return grouped;
  }

  String _formatTimeOnly(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = AppDateUtils.parseDateTime(createdAt);
    if (dt != null) {
      return DateFormat('h:mm a').format(dt);
    }
    return createdAt;
  }

  Color _getCategoryBgColor(AuditLogCategory cat, bool isDark) {
    switch (cat) {
      case AuditLogCategory.user:
        return isDark ? const Color(0xFF231834) : const Color(0xFFF2E8FD);
      case AuditLogCategory.match:
        return isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
      case AuditLogCategory.refund:
        return isDark ? const Color(0xFF2E1318) : const Color(0xFFFDE8E8);
      case AuditLogCategory.system:
        return isDark ? const Color(0xFF122234) : const Color(0xFFE8F2FD);
    }
  }

  Color _getCategoryIconColor(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.user:
        return const Color(0xFF8E24AA);
      case AuditLogCategory.match:
        return const Color(0xFF00C853);
      case AuditLogCategory.refund:
        return const Color(0xFFE53935);
      case AuditLogCategory.system:
        return const Color(0xFF1E88E5);
    }
  }

  IconData _getCategoryIcon(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.user:
        return Icons.person_outline_rounded;
      case AuditLogCategory.match:
        return Icons.sports_soccer_rounded;
      case AuditLogCategory.refund:
        return Icons.receipt_long_outlined;
      case AuditLogCategory.system:
        return Icons.security_rounded;
    }
  }

  String _getCategoryBadgeLabel(AuditLogCategory cat) {
    switch (cat) {
      case AuditLogCategory.user:
        return 'USER & MANAGER';
      case AuditLogCategory.match:
        return 'MATCH & SLOT';
      case AuditLogCategory.refund:
        return 'REFUND & CANCEL';
      case AuditLogCategory.system:
        return 'SYSTEM & VENUE';
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
                      hint: 'Search logs by event, admin or details...',
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

                        final filteredLogs = controller.auditLogs.where((log) {
                          final cat = _getCategory(log);
                          if (categoryFilter != 'ALL') {
                            if (categoryFilter == 'USER' &&
                                cat != AuditLogCategory.user) {
                              return false;
                            }
                            if (categoryFilter == 'MATCH' &&
                                cat != AuditLogCategory.match) {
                              return false;
                            }
                            if (categoryFilter == 'REFUND' &&
                                cat != AuditLogCategory.refund) {
                              return false;
                            }
                            if (categoryFilter == 'SYSTEM' &&
                                cat != AuditLogCategory.system) {
                              return false;
                            }
                          }

                          if (query.isNotEmpty) {
                            final actionMatch =
                                log.action.toLowerCase().contains(query);
                            final detailsMatch = (log.details ?? '')
                                .toLowerCase()
                                .contains(query);
                            final adminMatch = (log.adminName ?? '')
                                .toLowerCase()
                                .contains(query);
                            final targetMatch = (log.target ?? '')
                                .toLowerCase()
                                .contains(query);
                            return actionMatch ||
                                detailsMatch ||
                                adminMatch ||
                                targetMatch;
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
                                ],
                              ),
                            ),
                          );
                        }

                        final groupedLogs = _groupLogsByDate(filteredLogs);

                        return RefreshIndicator(
                          color: AppColors.primary,
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
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkCard
                                                : const Color(0xFFE2E8F0),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            dateHeader,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : const Color(0xFFE2E8F0),
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${logsForDate.length} ${logsForDate.length == 1 ? "event" : "events"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
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
                                            mainAxisExtent: 140,
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
      final allLogs = controller.auditLogs;

      final countAll = allLogs.length;
      final countUser =
          allLogs.where((l) => _getCategory(l) == AuditLogCategory.user).length;
      final countMatch = allLogs
          .where((l) => _getCategory(l) == AuditLogCategory.match)
          .length;
      final countRefund = allLogs
          .where((l) => _getCategory(l) == AuditLogCategory.refund)
          .length;
      final countSystem = allLogs
          .where((l) => _getCategory(l) == AuditLogCategory.system)
          .length;

      final current = selectedCategoryFilter.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('ALL', 'All Events ($countAll)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'USER', 'Users & Managers ($countUser)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'MATCH', 'Matches & Slots ($countMatch)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'REFUND', 'Cancelled & Refunded ($countRefund)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'SYSTEM', 'System & Venues ($countSystem)', current, isDark),
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
    final humanTitle = _getHumanReadableTitle(log.action);
    final timeStr = _formatTimeOnly(log.createdAt);

    final actorName = (log.adminName != null && log.adminName!.isNotEmpty)
        ? log.adminName!
        : 'System';
    final targetName = log.target;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(() => AdminAuditLogDetailView(auditLog: log));
          },
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
                        humanTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Actor & Target Metadata Row
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'By: $actorName',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF475569),
                            ),
                          ),
                          if (targetName != null &&
                              targetName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('•',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey.shade400)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Target: $targetName',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log.details != null &&
                          log.details!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.details!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade600,
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
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(height: 16, width: 80, shape: BoxShape.circle),
          SizedBox(height: 10),
          AppShimmer(height: 14, width: 200),
          SizedBox(height: 6),
          AppShimmer(height: 12, width: 140),
        ],
      ),
    );
  }
}
