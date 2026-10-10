import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/security/deep_link_service.dart';
import '../../../app/theme/app_colors.dart';

class NotificationDetailView extends StatefulWidget {
  final NotificationModel? notification;

  const NotificationDetailView({super.key, this.notification});

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  late NotificationModel item;

  @override
  void initState() {
    super.initState();
    if (widget.notification != null) {
      item = widget.notification!;
    } else if (Get.arguments is NotificationModel) {
      item = Get.arguments as NotificationModel;
    } else {
      item = NotificationModel(
        id: 'N/A',
        title: 'Notification Details',
        body: 'No notification content available.',
        type: 'SYSTEM',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  Color _getBadgeColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('SUCCESS') || t.contains('CONFIRMED') || t.contains('MATCH_START')) {
      return const Color(0xFF00C853);
    }
    if (t.contains('WARNING') || t.contains('ALERT') || t.contains('REFUND') || t.contains('CANCEL')) {
      return AppColors.error;
    }
    if (t.contains('CCTV') || t.contains('BOOKING')) {
      return const Color(0xFF0288D1);
    }
    return AppColors.primary;
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('MATCH') || t.contains('GAME')) return Icons.sports_soccer_rounded;
    if (t.contains('REFUND') || t.contains('WALLET') || t.contains('PAYMENT')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (t.contains('CCTV') || t.contains('VIDEO')) return Icons.videocam_rounded;
    if (t.contains('WARNING') || t.contains('ALERT')) return Icons.warning_amber_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatFullDate(String createdAt) {
    if (createdAt.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('EEEE, d MMMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getBadgeColor(item.type);
    final iconData = _getCategoryIcon(item.type);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Detail'),
        centerTitle: true,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop =
              deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrDesktop ? 32.0 : 16.0,
                vertical: 20.0,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrDesktop ? 650 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // Top Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
                            // Circular Category Icon Badge
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Center(
                                child: Icon(iconData, color: color, size: 30),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Notification Title
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Type & Read Status Badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.type.replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isRead
                                        ? Colors.grey.withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.isRead ? 'Read' : 'Unread',
                                    style: TextStyle(
                                      color: item.isRead ? Colors.grey : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full Notification Body Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message Content',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            SelectableText(
                              item.body,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.5,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Metadata Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timestamp & Metadata',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatFullDate(item.createdAt),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Deep Link / Action Button if link data exists
                      if (item.data != null && item.data!['link'] != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final uri = Uri.parse(item.data!['link'].toString());
                              DeepLinkService.handleUri(uri);
                            },
                            icon: const Icon(Icons.open_in_new_rounded,
                                color: Colors.white, size: 18),
                            label: const Text(
                              'View Action / Open Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
