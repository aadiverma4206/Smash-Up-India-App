import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';

class AdminPaymentDetailView extends GetView<AdminController> {
  const AdminPaymentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final payment = Get.arguments as AdminPaymentModel?;

    if (payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Details')),
        body: const Center(child: Text('Payment details not available.')),
      );
    }

    final isCancelled = payment.status == 'CANCELLED';
    final isRefunded = payment.status == 'REFUNDED';
    final avatarUrl = ImageUtils.resolveImageUrl(payment.userAvatar);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment & Match Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Amount & Status Card
            _buildHeaderAmountCard(context, payment, isCancelled, isRefunded),

            const SizedBox(height: 16),

            // Player Profile Info Card
            _buildPlayerInfoCard(context, payment, avatarUrl),

            const SizedBox(height: 16),

            // Match & Booking Details Card
            _buildMatchDetailsCard(context, payment),

            const SizedBox(height: 16),

            // CCTV Video Recording Card
            _buildCctvVideoCard(context, payment),

            if (isCancelled || isRefunded) ...[
              const SizedBox(height: 16),
              // Cancelled & Refund Information Card
              _buildRefundSectionCard(
                  context, payment, isCancelled, isRefunded),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAmountCard(
    BuildContext context,
    AdminPaymentModel payment,
    bool isCancelled,
    bool isRefunded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = isCancelled || isRefunded;

    Color statusBg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9);
    Color statusText =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32);

    if (isCancelled) {
      statusBg = isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE);
      statusText = isDark ? const Color(0xFFF87171) : const Color(0xFFC62828);
    } else if (isRefunded) {
      statusBg = isDark ? const Color(0xFF3A2814) : const Color(0xFFFFF3E0);
      statusText = isDark ? const Color(0xFFFBBF24) : const Color(0xFFEF6C00);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Payment Amount',
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${payment.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isNegative
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00C853),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              payment.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Transaction ID: ${payment.id}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Monospace',
              color:
                  isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoCard(
    BuildContext context,
    AdminPaymentModel payment,
    String? avatarUrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        payment.userName.isNotEmpty
                            ? payment.userName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.userEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      payment.userPhone,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsCard(
    BuildContext context,
    AdminPaymentModel payment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match & Court Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            icon: Icons.sports_soccer_rounded,
            label: 'Match Title',
            value: payment.matchTitle,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            icon: Icons.stadium_rounded,
            label: 'Turf Club',
            value: payment.clubName,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            icon: Icons.stadium_outlined,
            label: 'Court Name',
            value: payment.courtName,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            icon: Icons.scoreboard_rounded,
            label: 'Final Score',
            value: payment.score,
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Scheduled Time',
            value: payment.matchTime ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildCctvVideoCard(
    BuildContext context,
    AdminPaymentModel payment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVid = payment.hasVideo && payment.videoUrl != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CCTV Match Recording',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVid
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasVid ? 'AVAILABLE' : 'PROCESSING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasVid ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasVid) ...[
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Full HD CCTV Stream',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CCTV video recording for this match is currently being rendered or unavailable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundSectionCard(
    BuildContext context,
    AdminPaymentModel payment,
    bool isCancelled,
    bool isRefunded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE).withValues(alpha: isDark ? 0.15 : 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                isRefunded ? 'Match Refunded' : 'Match Cancelled',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Reason: ${payment.refundReason ?? "Match Cancelled by Manager/Admin"}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Refund Amount: ₹${payment.refundAmount > 0 ? payment.refundAmount.toStringAsFixed(0) : payment.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          if (isCancelled && !isRefunded) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showProcessRefundDialog(context, payment),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Issue Refund to Player'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showProcessRefundDialog(
      BuildContext context, AdminPaymentModel payment) {
    final reasonController = TextEditingController(
      text: 'Match cancelled refund issued by Admin',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Issue Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refund Amount: ₹${payment.amount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Refund Reason / Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.processRefund(
                payment.id,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ??
                  (isDark ? AppColors.textPrimaryDark : Colors.black87),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
