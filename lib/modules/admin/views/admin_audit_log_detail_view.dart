import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/responsive/responsive_builder.dart';
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

  Color _getBadgeColor(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') ||
        act.contains('success') ||
        act.contains('confirm')) {
      return Colors.green;
    }
    if (act.contains('refund') ||
        act.contains('cancel') ||
        act.contains('suspend')) {
      return AppColors.error;
    }
    if (act.contains('join') ||
        act.contains('create') ||
        act.contains('user')) {
      return Colors.purple;
    }
    return AppColors.primary;
  }

  IconData _getCategoryIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('approved') || act.contains('confirm')) {
      return Icons.check_circle_rounded;
    }
    if (act.contains('refund') || act.contains('payment')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (act.contains('cancel')) {
      return Icons.cancel_rounded;
    }
    if (act.contains('score') || act.contains('match')) {
      return Icons.emoji_events_rounded;
    }
    if (act.contains('join') || act.contains('user')) {
      return Icons.person_add_rounded;
    }
    return Icons.security_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getBadgeColor(log.action);
    final iconData = _getCategoryIcon(log.action);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Audit Log Details'),
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
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
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
                              log.action,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
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
                                  log.createdAt.length >= 19
                                      ? log.createdAt
                                          .substring(0, 19)
                                          .replaceAll('T', ' ')
                                      : log.createdAt,
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
                              'Event Description & Details',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            Text(
                              log.details != null && log.details!.isNotEmpty
                                  ? log.details!
                                  : 'No further details recorded for this system action.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                              'System & Technical Metadata',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            _buildMetaRow(context, Icons.badge_outlined,
                                'Log ID', log.id),
                            _buildMetaRow(
                              context,
                              Icons.person_outline_rounded,
                              'Initiator / User ID',
                              log.userId != null && log.userId!.isNotEmpty
                                  ? log.userId!
                                  : 'System Event',
                            ),
                            _buildMetaRow(
                              context,
                              Icons.network_check_rounded,
                              'IP Address',
                              log.ipAddress != null && log.ipAddress!.isNotEmpty
                                  ? log.ipAddress!
                                  : '127.0.0.1 (Local System)',
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
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87,
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
