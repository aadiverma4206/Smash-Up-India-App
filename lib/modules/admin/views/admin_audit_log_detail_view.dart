import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../app/theme/app_colors.dart';

class AdminAuditLogDetailView extends StatefulWidget {
  final AuditLogModel? auditLog;

  const AdminAuditLogDetailView({super.key, this.auditLog});

  @override
  State<AdminAuditLogDetailView> createState() =>
      _AdminAuditLogDetailViewState();
}

class _AdminAuditLogDetailViewState extends State<AdminAuditLogDetailView> {
  late AuditLogModel log;

  @override
  void initState() {
    super.initState();
    if (widget.auditLog != null) {
      log = widget.auditLog!;
    } else if (Get.arguments is AuditLogModel) {
      log = Get.arguments as AuditLogModel;
    } else {
      log = AuditLogModel(
        id: 'N/A',
        action: 'SYSTEM_EVENT',
        details: 'No event details recorded.',
        createdAt: '',
      );
    }
  }

  String _getHumanTitle(String rawAction, AuditLogParsedData parsed) {
    if (parsed.isMatchCancelled) {
      return 'Match Cancelled & Refunded';
    }
    if (parsed.isUserBlockUnblock) {
      return parsed.isBlocked
          ? 'Player Account Blocked'
          : 'Player Account Unblocked';
    }
    if (parsed.isMatchCreated) {
      return 'New Match Created';
    }

    final act = rawAction.trim().toUpperCase();
    switch (act) {
      case 'MANAGER_ACCOUNT_CREATED':
        return 'Manager Account Created';
      case 'ADMIN_ACCOUNT_CREATED':
        return 'Admin Account Created';
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

  Color _getBadgeColor(AuditLogParsedData parsed) {
    if (parsed.isMatchCancelled) {
      return const Color(0xFFE53935);
    }
    if (parsed.isUserBlockUnblock) {
      return parsed.isBlocked
          ? const Color(0xFFE65100)
          : const Color(0xFF00C853);
    }
    if (parsed.isMatchCreated) {
      return const Color(0xFF00C853);
    }
    return const Color(0xFF1E88E5);
  }

  IconData _getCategoryIcon(AuditLogParsedData parsed) {
    if (parsed.isMatchCancelled) {
      return Icons.cancel_rounded;
    }
    if (parsed.isUserBlockUnblock) {
      return parsed.isBlocked
          ? Icons.block_rounded
          : Icons.check_circle_rounded;
    }
    if (parsed.isMatchCreated) {
      return Icons.sports_soccer_rounded;
    }
    return Icons.security_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = log.parsed;
    final badgeColor = _getBadgeColor(parsed);
    final iconData = _getCategoryIcon(parsed);
    final humanTitle = _getHumanTitle(log.action, parsed);

    final actorName = (log.adminName != null && log.adminName!.isNotEmpty)
        ? log.adminName!
        : (log.userId != null && log.userId!.isNotEmpty
            ? log.userId!
            : 'System');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Audit Log Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.lightBlueAppBar,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
        ),
        centerTitle: true,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop = deviceType == DeviceType.tablet ||
              deviceType == DeviceType.desktop;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrDesktop ? 32.0 : 16.0,
                vertical: 16.0,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrDesktop ? 650 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // Header Event Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: badgeColor, width: 2),
                              ),
                              child: Center(
                                child:
                                    Icon(iconData, color: badgeColor, size: 30),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              humanTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (log.createdAt.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  AppDateUtils.formatDateTime(log.createdAt,
                                      format: 'dd MMM yyyy, h:mm a'),
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dedicated Information Section based on Category
                      if (parsed.isMatchCancelled)
                        _buildMatchCancelledDetailSection(context, parsed)
                      else if (parsed.isUserBlockUnblock)
                        _buildUserBlockUnblockDetailSection(context, parsed)
                      else if (parsed.isMatchCreated)
                        _buildMatchCreatedDetailSection(context, parsed)
                      else
                        _buildNarrativeBanner(
                            context, actorName, humanTitle, log.details),

                      const SizedBox(height: 16),

                      // Event Description Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Notes & Details',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const Divider(height: 20),
                            Text(
                              log.details != null && log.details!.isNotEmpty
                                  ? log.details!
                                  : 'No further details recorded for this system action.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actor & Metadata Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actor & System Metadata',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const Divider(height: 20),
                            _buildMetaRow(
                              context,
                              Icons.person_pin_rounded,
                              'Action Initiated By',
                              actorName,
                            ),
                            _buildMetaRow(
                              context,
                              Icons.badge_outlined,
                              'Target Entity',
                              parsed.isUserBlockUnblock
                                  ? parsed.playerName
                                  : (parsed.isMatchCancelled ||
                                          parsed.isMatchCreated
                                      ? parsed.matchTitle
                                      : (log.target ?? 'System Entity')),
                            ),
                            _buildMetaRow(
                              context,
                              Icons.receipt_long_outlined,
                              'Log ID',
                              '#${log.id}',
                            ),
                            _buildMetaRow(
                              context,
                              Icons.network_check_rounded,
                              'IP Address',
                              log.ipAddress != null && log.ipAddress!.isNotEmpty
                                  ? log.ipAddress!
                                  : '127.0.0.1 (Local Network)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. MATCH CANCELLED DETAIL SECTION
  Widget _buildMatchCancelledDetailSection(
      BuildContext context, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5A1E24) : const Color(0xFFFECDD3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  color: Color(0xFFE53935), size: 20),
              const SizedBox(width: 8),
              Text(
                'Match Cancellation Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildMetaRow(context, Icons.sports_soccer_rounded, 'Match Name',
              parsed.matchTitle),
          _buildMetaRow(context, Icons.cancel_schedule_send_rounded,
              'Cancelled By', parsed.cancelledBy),
          _buildMetaRow(
              context, Icons.star_rounded, 'Match Host', parsed.hostName),
          _buildMetaRow(context, Icons.access_time_rounded,
              'Scheduled Match Time', parsed.scheduledTime),
          _buildMetaRow(context, Icons.payments_outlined, 'Match Entry Fee',
              parsed.matchAmount),
          _buildMetaRow(context, Icons.replay_rounded, 'Total Refund Processed',
              parsed.refundAmount,
              valueColor: const Color(0xFF00C853)),
          _buildMetaRow(context, Icons.help_outline_rounded,
              'Cancellation Reason', parsed.cancellationReason),
        ],
      ),
    );
  }

  // 2. PLAYER BLOCK / UNBLOCK DETAIL SECTION
  Widget _buildUserBlockUnblockDetailSection(
      BuildContext context, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked = parsed.isBlocked;
    final badgeColor =
        isBlocked ? const Color(0xFFE65100) : const Color(0xFF00C853);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                color: badgeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBlocked
                    ? 'Player Account Suspension'
                    : 'Player Account Restoration',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildMetaRow(
              context, Icons.person_rounded, 'Player Name', parsed.playerName),
          _buildMetaRow(context, Icons.phone_android_rounded, 'Mobile Number',
              parsed.playerPhone),
          _buildMetaRow(context, Icons.email_outlined, 'Email Address',
              parsed.playerEmail),
          _buildMetaRow(context, Icons.security_rounded, 'Status',
              isBlocked ? 'BLOCKED / SUSPENDED' : 'ACTIVE / UNBLOCKED',
              valueColor: badgeColor),
          _buildMetaRow(context, Icons.admin_panel_settings_outlined,
              'Action Performed By', parsed.actionBy),
          _buildMetaRow(context, Icons.info_outline_rounded, 'Reason / Note',
              parsed.userActionReason),
        ],
      ),
    );
  }

  // 3. MATCH CREATED DETAIL SECTION
  Widget _buildMatchCreatedDetailSection(
      BuildContext context, AuditLogParsedData parsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00C853).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_soccer_rounded,
                  color: Color(0xFF00C853), size: 20),
              const SizedBox(width: 8),
              Text(
                'Match Creation Setup',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildMetaRow(context, Icons.sports_soccer_rounded, 'Match Title',
              parsed.matchTitle),
          _buildMetaRow(context, Icons.person_outline_rounded, 'Created By',
              parsed.createdBy),
          _buildMetaRow(
              context, Icons.star_rounded, 'Host Player', parsed.hostName),
          _buildMetaRow(
              context, Icons.grass_rounded, 'Turf Court', parsed.courtName),
          _buildMetaRow(
              context, Icons.sports_rounded, 'Format', parsed.matchFormat),
          _buildMetaRow(context, Icons.confirmation_number_outlined,
              'Entry Fee', parsed.entryFee),
          _buildMetaRow(context, Icons.access_time_rounded, 'Scheduled Time',
              parsed.scheduledTime),
        ],
      ),
    );
  }

  Widget _buildNarrativeBanner(
      BuildContext context, String actor, String title, String? details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$actor executed $title.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
