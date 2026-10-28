import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'player_notification.dart';
import '../../../data/models/notification_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/security/deep_link_service.dart';

class PlayerNotificationDetailView extends StatelessWidget {
  final PlayerNotificationItem? item;
  final NotificationModel? model;

  const PlayerNotificationDetailView({
    super.key,
    this.item,
    this.model,
  });

  PlayerNotificationItem _resolveItem() {
    if (item != null) return item!;
    if (model != null) return _mapModelToPlayerItem(model!);

    final args = Get.arguments;
    if (args is PlayerNotificationItem) return args;
    if (args is NotificationModel) return _mapModelToPlayerItem(args);

    return PlayerNotificationItem(
      id: 'N/A',
      title: 'Notification Details',
      subtitle: 'No notification details available.',
      category: 'SYSTEM',
      icon: Icons.notifications_active_rounded,
      iconColor: AppColors.primary,
      iconBgLight: const Color(0xFFDCFCE7),
      iconBgDark: const Color(0xFF0F331A),
      dateTime: DateTime.now(),
      isRead: true,
    );
  }

  PlayerNotificationItem _mapModelToPlayerItem(NotificationModel m) {
    final parsedDt = AppDateUtils.parseDateTime(m.createdAt) ?? DateTime.now();
    final type = m.type.toUpperCase();
    String category = 'SYSTEM';
    IconData icon = Icons.notifications_none_rounded;
    Color iconColor = AppColors.primary;
    Color iconBgLight = const Color(0xFFDCFCE7);
    Color iconBgDark = const Color(0xFF0F331A);

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
    } else if (type.contains('APPROVED')) {
      category = 'MATCH';
      icon = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF16A34A);
      iconBgLight = const Color(0xFFDCFCE7);
      iconBgDark = const Color(0xFF0F331A);
    } else if (type.contains('MATCH') || type.contains('GAME')) {
      category = 'MATCH';
      icon = Icons.sports_soccer_rounded;
      iconColor = AppColors.primary;
      iconBgLight = const Color(0xFFDCFCE7);
      iconBgDark = const Color(0xFF0F331A);
    }

    return PlayerNotificationItem(
      id: m.id,
      title: AppDateUtils.sanitizeNotificationText(m.title),
      subtitle: AppDateUtils.sanitizeNotificationText(m.body),
      category: category,
      icon: icon,
      iconColor: iconColor,
      iconBgLight: iconBgLight,
      iconBgDark: iconBgDark,
      dateTime: parsedDt,
      isRead: m.isRead,
      data: m.data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final PlayerNotificationItem notification = _resolveItem();

    final String formattedDate =
        DateFormat('EEEE, d MMMM yyyy • h:mm a').format(notification.dateTime);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.sageGreenAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notification Detail',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                children: [
                  // Samsung One UI Header Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: isDark
                                ? notification.iconBgDark
                                : notification.iconBgLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: notification.iconColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              notification.icon,
                              color: notification.iconColor,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          notification.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: notification.iconColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                notification.category,
                                style: TextStyle(
                                  color: notification.iconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (notification.badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: notification.badgeBgColor ??
                                      const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  notification.badgeText!,
                                  style: TextStyle(
                                    color: notification.badgeTextColor ??
                                        const Color(0xFFD97706),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Samsung SMS Message Content Card
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Message Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        SelectableText(
                          notification.subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timestamp Card
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
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Deep Link / Action Button
                  if (notification.data != null &&
                      notification.data!['link'] != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final uri =
                              Uri.parse(notification.data!['link'].toString());
                          DeepLinkService.handleUri(uri);
                        },
                        icon: const Icon(Icons.open_in_new_rounded,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'View Related Action / Link',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text('Back to Notifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
