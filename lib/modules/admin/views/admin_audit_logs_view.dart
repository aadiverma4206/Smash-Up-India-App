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

abstract class AuditLogListItem {}

class AuditDateHeaderItem extends AuditLogListItem {
  final String dateHeader;
  final int count;
  AuditDateHeaderItem(this.dateHeader, this.count);
}

class AuditLogCardItem extends AuditLogListItem {
  final AuditLogModel log;
  AuditLogCardItem(this.log);
}

class AuditLogLoadingItem extends AuditLogListItem {}

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

  List<AuditLogListItem> _buildDisplayItems(
      List<AuditLogModel> filteredLogs, bool hasMore) {
    final List<AuditLogListItem> items = [];
    final grouped = _groupLogsByDate(filteredLogs);

    for (final entry in grouped.entries) {
      items.add(AuditDateHeaderItem(entry.key, entry.value.length));
      for (final log in entry.value) {
        items.add(AuditLogCardItem(log));
      }
    }

    if (hasMore) {
      items.add(AuditLogLoadingItem());
    }

    return items;
  }

  String _formatTimeOnly(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = AppDateUtils.parseDateTime(createdAt);
    if (dt != null) {
      return DateFormat('h:mm a').format(dt);
    }
    return createdAt;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.lightBlueAppBar,
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
                      hint: 'Search logs by match, player, email, phone...',
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
                          return _buildShimmerView(context);
                        }

                        final query = filterQuery.value;
                        final categoryFilter = selectedCategoryFilter.value;

                        final filteredLogs = controller.auditLogs.where((log) {
                          final parsed = log.parsed;

                          if (categoryFilter != 'ALL') {
                            if (categoryFilter == 'CANCELLED' &&
                                !parsed.isMatchCancelled) {
                              return false;
                            }
                            if (categoryFilter == 'USER_BLOCK' &&
                                !parsed.isUserBlockUnblock) {
                              return false;
                            }
                            if (categoryFilter == 'CREATED' &&
                                !parsed.isMatchCreated) {
                              return false;
                            }
                            if (categoryFilter == 'SYSTEM' &&
                                (parsed.isMatchCancelled ||
                                    parsed.isUserBlockUnblock ||
                                    parsed.isMatchCreated)) {
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
                            final playerMatch =
                                parsed.playerName.toLowerCase().contains(query);
                            final emailMatch = parsed.playerEmail
                                .toLowerCase()
                                .contains(query);
                            final phoneMatch = parsed.playerPhone
                                .toLowerCase()
                                .contains(query);
                            final matchTitleMatch =
                                parsed.matchTitle.toLowerCase().contains(query);

                            return actionMatch ||
                                detailsMatch ||
                                adminMatch ||
                                targetMatch ||
                                playerMatch ||
                                emailMatch ||
                                phoneMatch ||
                                matchTitleMatch;
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

                        final displayItems = _buildDisplayItems(
                            filteredLogs, controller.hasMoreAuditLogs.value);

                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => controller.fetchAuditLogs(),
                          child: ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= displayItems.length) {
                                return const SizedBox.shrink();
                              }

                              final item = displayItems[index];

                              if (item is AuditDateHeaderItem) {
                                return _buildDateHeader(context, item);
                              } else if (item is AuditLogCardItem) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _buildAuditLogCard(context, item.log),
                                );
                              } else if (item is AuditLogLoadingItem) {
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

                              return const SizedBox.shrink();
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
      final countCancelled =
          allLogs.where((l) => l.parsed.isMatchCancelled).length;
      final countUserBlock =
          allLogs.where((l) => l.parsed.isUserBlockUnblock).length;
      final countCreated = allLogs.where((l) => l.parsed.isMatchCreated).length;
      final countSystem = allLogs
          .where((l) =>
              !l.parsed.isMatchCancelled &&
              !l.parsed.isUserBlockUnblock &&
              !l.parsed.isMatchCreated)
          .length;

      final current = selectedCategoryFilter.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('ALL', 'All Events ($countAll)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip('CANCELLED', 'Match Cancelled ($countCancelled)',
                current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip('USER_BLOCK',
                'Player Block/Unblock ($countUserBlock)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'CREATED', 'Match Created ($countCreated)', current, isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
                'SYSTEM', 'System ($countSystem)', current, isDark),
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

  Widget _buildDateHeader(BuildContext context, AuditDateHeaderItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          const EdgeInsets.only(top: 14.0, bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.dateHeader,
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
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.count} ${item.count == 1 ? "event" : "events"}',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context, AuditLogModel log) {
    final parsed = log.parsed;

    if (parsed.isMatchCancelled) {
      return _buildMatchCancelledCard(context, log, parsed);
    } else if (parsed.isUserBlockUnblock) {
      return _buildUserBlockUnblockCard(context, log, parsed);
    } else if (parsed.isMatchCreated) {
      return _buildMatchCreatedCard(context, log, parsed);
    } else {
      return _buildSystemEventCard(context, log, parsed);
    }
  }

  // --------------------------------------------------------------------------
  // 1. MATCH CANCELLED CARD UI
  // --------------------------------------------------------------------------
  Widget _buildMatchCancelledCard(
      BuildContext context, AuditLogModel log, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = _formatTimeOnly(log.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5A1E24) : const Color(0xFFFECDD3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badge & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_outlined,
                              size: 13, color: Color(0xFFE53935)),
                          SizedBox(width: 4),
                          Text(
                            'MATCH CANCELLED & REFUNDED',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 8),

                // Match Title
                Text(
                  parsed.matchTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Details Grid (Cancelled By, Host, Scheduled, Amounts)
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.person_remove_rounded,
                        'Cancelled By',
                        parsed.cancelledBy,
                        valueColor: const Color(0xFFE53935),
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.star_rounded,
                        'Match Host',
                        parsed.hostName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.payments_outlined,
                        'Match Amount',
                        parsed.matchAmount,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.replay_rounded,
                        'Refund Credited',
                        parsed.refundAmount,
                        valueColor: const Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
                if (parsed.cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${parsed.cancellationReason}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. PLAYER BLOCK / UNBLOCK CARD UI
  // --------------------------------------------------------------------------
  Widget _buildUserBlockUnblockCard(
      BuildContext context, AuditLogModel log, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked = parsed.isBlocked;
    final badgeColor =
        isBlocked ? const Color(0xFFE65100) : const Color(0xFF00C853);
    final borderColor = isDark
        ? (isBlocked ? const Color(0xFF5A2A1E) : const Color(0xFF1E5A35))
        : (isBlocked ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9));
    final timeStr = _formatTimeOnly(log.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badge & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBlocked
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 13,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBlocked ? 'PLAYER BLOCKED' : 'PLAYER UNBLOCKED',
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 8),

                // Player Full Name
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 18, color: badgeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        parsed.playerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Player Contact Details (Mobile & Email - NO Mongo raw ID)
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.phone_android_rounded,
                        'Mobile Number',
                        parsed.playerPhone,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.email_outlined,
                        'Email Address',
                        parsed.playerEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.admin_panel_settings_outlined,
                        'Action By',
                        parsed.actionBy,
                        valueColor: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.info_outline_rounded,
                        'Action Note',
                        parsed.userActionReason,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. MATCH CREATED CARD UI
  // --------------------------------------------------------------------------
  Widget _buildMatchCreatedCard(
      BuildContext context, AuditLogModel log, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = _formatTimeOnly(log.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E5A35) : const Color(0xFFA7F3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF00C853).withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badge & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_soccer_rounded,
                              size: 13, color: Color(0xFF00C853)),
                          SizedBox(width: 4),
                          Text(
                            'NEW MATCH CREATED',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 8),

                // Match Title
                Text(
                  parsed.matchTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Details Grid (Created By, Court, Scheduled, Entry Fee)
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.person_outline_rounded,
                        'Created By',
                        parsed.createdBy,
                        valueColor: const Color(0xFF00C853),
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.grass_rounded,
                        'Turf Court',
                        parsed.courtName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.sports_rounded,
                        'Match Format',
                        parsed.matchFormat,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniDetailItem(
                        context,
                        Icons.confirmation_number_outlined,
                        'Entry Fee',
                        parsed.entryFee,
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. SYSTEM EVENT CARD UI
  // --------------------------------------------------------------------------
  Widget _buildSystemEventCard(
      BuildContext context, AuditLogModel log, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = _formatTimeOnly(log.createdAt);
    final actorName = (log.adminName != null && log.adminName!.isNotEmpty)
        ? log.adminName!
        : 'System';

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
                    color: isDark
                        ? const Color(0xFF122234)
                        : const Color(0xFFE8F2FD),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.security_rounded,
                        color: Color(0xFF1E88E5), size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SYSTEM EVENT',
                              style: TextStyle(
                                color: Color(0xFF1E88E5),
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
                          fontSize: 14.5,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
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
                      if (log.details != null && log.details!.isNotEmpty) ...[
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

  Widget _buildMiniDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon,
            size: 13,
            color:
                isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor ??
                      (isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerView(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _buildSingleShimmerCard(context),
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
          AppShimmer(height: 16, width: 120, shape: BoxShape.rectangle),
          SizedBox(height: 10),
          AppShimmer(height: 16, width: 220),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: AppShimmer(height: 12, width: 100)),
              SizedBox(width: 12),
              Expanded(child: AppShimmer(height: 12, width: 100)),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: AppShimmer(height: 12, width: 100)),
              SizedBox(width: 12),
              Expanded(child: AppShimmer(height: 12, width: 100)),
            ],
          ),
        ],
      ),
    );
  }
}
