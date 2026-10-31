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

  String _getHumanTitle(String rawAction) {
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

  String _sanitizeTarget(String? rawTarget) {
    if (rawTarget == null || rawTarget.trim().isEmpty) return 'N/A';
    final target = rawTarget.trim();
    if (target.startsWith('User:usr_') || target.startsWith('usr_')) {
      final cleanId = target.replaceFirst('User:', '').trim();
      if (cleanId.length > 12) {
        return 'User Account (${cleanId.substring(0, 10)}...)';
      }
      return 'User Account ($cleanId)';
    }
    return target;
  }

  Color _getBadgeColor(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') ||
        act.contains('success') ||
        act.contains('confirm') ||
        act.contains('completed')) {
      return const Color(0xFF00C853);
    }
    if (act.contains('refund') ||
        act.contains('cancel') ||
        act.contains('suspend')) {
      return const Color(0xFFE53935);
    }
    if (act.contains('create') ||
        act.contains('user') ||
        act.contains('manager')) {
      return const Color(0xFF8E24AA);
    }
    return const Color(0xFF1E88E5);
  }

  IconData _getCategoryIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') || act.contains('confirm')) {
      return Icons.check_circle_rounded;
    }
    if (act.contains('refund') || act.contains('payment')) {
      return Icons.receipt_long_outlined;
    }
    if (act.contains('cancel')) {
      return Icons.cancel_rounded;
    }
    if (act.contains('score') || act.contains('match')) {
      return Icons.sports_soccer_rounded;
    }
    if (act.contains('user') || act.contains('manager')) {
      return Icons.person_outline_rounded;
    }
    return Icons.security_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getBadgeColor(log.action);
    final iconData = _getCategoryIcon(log.action);
    final humanTitle = _getHumanTitle(log.action);
    final cleanTarget = _sanitizeTarget(log.target);

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
            : AppColors.sageGreenAppBar,
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

                      // Event Summary Narrative Banner
                      _buildSummaryNarrativeCard(
                        context,
                        actor: actorName,
                        target: cleanTarget,
                        actionTitle: humanTitle,
                        details: log.details,
                      ),

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
                              'Event Description & Notes',
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

                      // Metadata Card
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
                              'Target Entity Affected',
                              cleanTarget,
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

  Widget _buildSummaryNarrativeCard(
    BuildContext context, {
    required String actor,
    required String target,
    required String actionTitle,
    required String? details,
  }) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(
                        text: actor,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' executed '),
                      TextSpan(
                        text: actionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (target != 'N/A') ...[
                        const TextSpan(text: ' on '),
                        TextSpan(
                          text: target,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                if (details != null && details.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Notes: ${details.trim()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
      BuildContext context, IconData icon, String label, String value) {
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
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
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
