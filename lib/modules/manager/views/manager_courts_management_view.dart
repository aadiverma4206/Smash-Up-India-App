import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../../../data/models/court_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';

class ManagerCourtsManagementView extends GetView<ManagerDashboardController> {
  const ManagerCourtsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Courts Management',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Manage pitch availability & 1-hour hourly pricing',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Courts',
            onPressed: () => controller.loadManagerData(),
          ),
        ],
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SkeletonContainer(
                    width: double.infinity, height: 70, borderRadius: 16),
                SizedBox(height: 16),
                Expanded(child: SkeletonListLoader(count: 3)),
              ],
            ),
          );
        }

        if (controller.courts.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Courts Found',
            subtitle:
                'No courts found for your assigned club. Tap refresh to try again.',
            icon: Icons.stadium_outlined,
          );
        }

        final courtsList = controller.courts;
        final availableCount =
            courtsList.where((c) => c.status.toUpperCase() == 'AVAILABLE').length;
        final maintenanceCount =
            courtsList.where((c) => c.status.toUpperCase() == 'MAINTENANCE').length;
        final blockedCount =
            courtsList.where((c) => c.status.toUpperCase() == 'BLOCKED').length;

        return RefreshIndicator(
          onRefresh: () => controller.loadManagerData(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildOverviewCard(
                context,
                total: courtsList.length,
                available: availableCount,
                maintenance: maintenanceCount,
                blocked: blockedCount,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pitches & Courts (${courtsList.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Rate: ₹ / 1 Hour',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...courtsList.map((court) => _buildCourtCard(context, court)),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required int total,
    required int available,
    required int maintenance,
    required int blocked,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turf Courts Status Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All rates are charged strictly per 1 Hour basis',
                      style: TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricItem(
                context,
                label: 'Total',
                value: '$total',
                color: Colors.blueAccent,
                icon: Icons.stadium_rounded,
              ),
              _buildMetricItem(
                context,
                label: 'Available',
                value: '$available',
                color: const Color(0xFF00C853),
                icon: Icons.check_circle_rounded,
              ),
              _buildMetricItem(
                context,
                label: 'Maintenance',
                value: '$maintenance',
                color: Colors.orangeAccent.shade700,
                icon: Icons.build_circle_rounded,
              ),
              _buildMetricItem(
                context,
                label: 'Blocked',
                value: '$blocked',
                color: Colors.redAccent,
                icon: Icons.block_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, CourtModel court) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = court.status.toUpperCase();

    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'AVAILABLE':
        statusColor = const Color(0xFF00C853);
        statusBgColor = const Color(0xFF00C853).withValues(alpha: 0.12);
        statusText = 'AVAILABLE';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'MAINTENANCE':
        statusColor = Colors.orangeAccent.shade700;
        statusBgColor = Colors.orange.withValues(alpha: 0.12);
        statusText = 'MAINTENANCE';
        statusIcon = Icons.build_rounded;
        break;
      case 'BLOCKED':
      default:
        statusColor = Colors.redAccent.shade700;
        statusBgColor = Colors.red.withValues(alpha: 0.12);
        statusText = 'BLOCKED';
        statusIcon = Icons.block_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.stadium_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            court.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag(court.surfaceType, Icons.grass_rounded),
                          const SizedBox(width: 6),
                          _buildTag(court.id, Icons.tag_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pricing Highlight Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1435)
                  : const Color(0xFFF7FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : const Color(0xFFD1E7DD),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hourly Price (1 Hour)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${court.basePricePerHour.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ hour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditCourtSheet(context, court),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text(
                    'Set Price & Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Quick status buttons strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                const Text(
                  'Quick Status:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                _buildQuickStatusChip(
                  context,
                  court: court,
                  targetStatus: 'AVAILABLE',
                  label: 'Available',
                  activeColor: const Color(0xFF00C853),
                ),
                const SizedBox(width: 6),
                _buildQuickStatusChip(
                  context,
                  court: court,
                  targetStatus: 'MAINTENANCE',
                  label: 'Maintenance',
                  activeColor: Colors.orangeAccent.shade700,
                ),
                const SizedBox(width: 6),
                _buildQuickStatusChip(
                  context,
                  court: court,
                  targetStatus: 'BLOCKED',
                  label: 'Blocked',
                  activeColor: Colors.redAccent.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusChip(
    BuildContext context, {
    required CourtModel court,
    required String targetStatus,
    required String label,
    required Color activeColor,
  }) {
    final isCurrent = court.status.toUpperCase() == targetStatus;

    return InkWell(
      onTap: isCurrent
          ? null
          : () {
              controller.updateCourtStatusAndPrice(
                courtId: court.id,
                basePrice: court.basePricePerHour,
                status: targetStatus,
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? activeColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isCurrent ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCourtSheet(BuildContext context, CourtModel court) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceController = TextEditingController(
      text: court.basePricePerHour.toStringAsFixed(0),
    );
    final selectedStatus = court.status.toUpperCase().obs;
    final isSaving = false.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit ${court.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Set 1-Hour pricing and availability status',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1-Hour Price Section
              Text(
                'Price Per 1 Hour (₹)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixText: '/ 1 Hour',
                  suffixStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkInputBg
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick increment price chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildIncrementChip(priceController, 500, label: '₹500/hr'),
                    _buildIncrementChip(priceController, 800, label: '₹800/hr'),
                    _buildIncrementChip(priceController, 1000, label: '₹1000/hr'),
                    _buildIncrementChip(priceController, 1200, label: '₹1200/hr'),
                    _buildIncrementChip(priceController, 1500, label: '₹1500/hr'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Selector
              Text(
                'Court Availability Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => Column(
                    children: [
                      _buildStatusOption(
                        context,
                        title: 'AVAILABLE',
                        subtitle:
                            'Pitch is open and ready for match creation & bookings',
                        color: const Color(0xFF00C853),
                        icon: Icons.check_circle_rounded,
                        current: selectedStatus.value,
                        onTap: () => selectedStatus.value = 'AVAILABLE',
                      ),
                      const SizedBox(height: 8),
                      _buildStatusOption(
                        context,
                        title: 'MAINTENANCE',
                        subtitle:
                            'Pitch is undergoing turf repairs or scheduled maintenance',
                        color: Colors.orangeAccent.shade700,
                        icon: Icons.build_rounded,
                        current: selectedStatus.value,
                        onTap: () => selectedStatus.value = 'MAINTENANCE',
                      ),
                      const SizedBox(height: 8),
                      _buildStatusOption(
                        context,
                        title: 'BLOCKED',
                        subtitle:
                            'Pitch is temporarily closed or blocked for private club events',
                        color: Colors.redAccent.shade700,
                        icon: Icons.block_rounded,
                        current: selectedStatus.value,
                        onTap: () => selectedStatus.value = 'BLOCKED',
                      ),
                    ],
                  )),
              const SizedBox(height: 24),

              // Action Buttons
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving.value
                          ? null
                          : () async {
                              final newPrice =
                                  double.tryParse(priceController.text.trim());
                              if (newPrice == null || newPrice < 0) {
                                Get.snackbar(
                                  'Invalid Price',
                                  'Please enter a valid price per 1 hour.',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              isSaving.value = true;
                              final ok = await controller
                                  .updateCourtStatusAndPrice(
                                courtId: court.id,
                                basePrice: newPrice,
                                status: selectedStatus.value,
                              );
                              isSaving.value = false;

                              if (ok) {
                                Get.back();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildIncrementChip(
    TextEditingController controller,
    int value, {
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          controller.text = value.toString();
        },
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == title;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? color
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: color, size: 18)
            else
              Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
