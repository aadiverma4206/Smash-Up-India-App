import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/courts_controller.dart';
import '../../../data/models/court_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/app_date_utils.dart';

class CourtsListView extends GetView<CourtsController> {
  const CourtsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Available Courts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar Section
            _buildFilterBarSection(context),

            // Main List & Chart Body
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.courts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  );
                }

                final filtered = controller.filteredCourts;

                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchCourts();
                    await controller.fetchScheduleForDate(
                        controller.chartSelectedDate.value);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title: Court Pitches
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stadium_rounded,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Court Pitches (${filtered.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filtered.isEmpty) ...[
                          _buildEmptyCourtsView(context),
                        ] else ...[
                          ...filtered.map((court) =>
                              _buildCourtCard(context, court, isDark)),
                        ],

                        // Court Hourly Availability Chart
                        _buildAvailabilityChartSection(context),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBarSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            onChanged: (val) => controller.setSearchQuery(val),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search court name, turf or city...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : Colors.grey.shade500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
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

          // Filter Status Label
          Text(
            'Filter By Status',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),

          // Status Filter Chips Row
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: 'All',
                      count: controller.totalCount,
                      statusKey: 'ALL',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      context: context,
                      label: 'Available',
                      count: controller.availableCount,
                      statusKey: 'AVAILABLE',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      context: context,
                      label: 'Maintenance',
                      count: controller.maintenanceCount,
                      statusKey: 'MAINTENANCE',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      context: context,
                      label: 'Blocked',
                      count: controller.blockedCount,
                      statusKey: 'BLOCKED',
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int count,
    required String statusKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = controller.selectedStatusFilter.value == statusKey;

    return InkWell(
      onTap: () => controller.setStatusFilter(statusKey),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtCard(
      BuildContext context, CourtModel court, bool isDark) {
    final status = court.status.toUpperCase();
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (status) {
      case 'AVAILABLE':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusText = 'AVAILABLE';
        break;
      case 'MAINTENANCE':
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        statusText = 'MAINTENANCE';
        break;
      case 'BLOCKED':
      default:
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
        statusText = 'BLOCKED';
        break;
    }

    final isAvailable = status == 'AVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Status Accent Bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.stadium_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${court.clubName} • ${court.city}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Status Badge
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
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Bottom Price & Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hourly Price',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '₹${court.basePricePerHour.toStringAsFixed(0)} / hr',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Book Pitch Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? AppColors.primary : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: isAvailable
                            ? () {
                                if (Get.isRegistered<ConnectivityService>() &&
                                    !ConnectivityService
                                        .to.isConnected.value) {
                                  ErrorHandler.showErrorSnackBar(
                                    'No Internet Connection',
                                    'Pitch booking requires an active internet connection. Please turn on mobile data or Wi-Fi to proceed.',
                                  );
                                  return;
                                }
                                Get.toNamed(Routes.createGame, arguments: {
                                  'courtId': court.id,
                                });
                              }
                            : null,
                        icon: const Icon(Icons.sports_soccer_rounded, size: 16),
                        label: Text(
                          isAvailable ? 'Book Pitch' : 'Unavailable',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCourtsView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.stadium_outlined,
              size: 48,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              'No Courts Found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No courts match your selected status filter or search query.',
              textAlign: TextAlign.center,
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
    );
  }

  Widget _buildAvailabilityChartSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Section Title
        Row(
          children: [
            const Icon(Icons.analytics_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Court Hourly Availability Chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Obx(
          () {
            final date = controller.chartSelectedDate.value;
            final dateFormatted =
                '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
            return Text(
              'Showing hourly availability graph for $dateFormatted',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Controls Card (Court selection & Date filter chips)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              // Court Selection Tabs
              Obx(() => Row(
                    children: [
                      Expanded(
                        child:
                            _buildChartCourtTab(context, 'court_1', 'Court 1'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _buildChartCourtTab(context, 'court_2', 'Court 2'),
                      ),
                    ],
                  )),
              const SizedBox(height: 10),

              // Date Selection Chips
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChartDateChip(
                            context, 'TODAY', 'Today', Icons.today_rounded),
                        const SizedBox(width: 6),
                        _buildChartDateChip(context, 'TOMORROW', 'Tomorrow',
                            Icons.upcoming_rounded),
                        const SizedBox(width: 6),
                        _buildChartDateChip(context, 'CUSTOM', 'Select Date',
                            Icons.date_range_rounded),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Chart Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            if (controller.isScheduleLoading.value) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            final activeCourt = controller.chartCourtId.value;
            final slots = controller.getSlotsForActiveCourt();
            final freeCount = controller.activeCourtAvailableSlotsCount;
            final bookedCount = controller.activeCourtBookedSlotsCount;
            final closedCount = controller.activeCourtUnavailableSlotsCount;

            final courtName = activeCourt == 'court_1' ? 'Court 1' : 'Court 2';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Stats inside Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$courtName Status Chart',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$freeCount Free Hours',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$bookedCount Booked',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF87171),
                            ),
                          ),
                        ),
                        if (closedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$closedCount Closed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Horizontally Scrollable Bar Graph Visualization
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: slots.map((slot) {
                            Color barColor;
                            double barHeight;

                            if (slot.isAvailable) {
                              barColor = const Color(0xFF10B981);
                              barHeight = 52.0;
                            } else if (slot.isBooked) {
                              barColor = const Color(0xFFEF4444);
                              barHeight = 88.0;
                            } else if (slot.isPending) {
                              barColor = const Color(0xFFF59E0B);
                              barHeight = 70.0;
                            } else {
                              barColor = const Color(0xFF64748B);
                              barHeight = 30.0;
                            }

                            final labelText = _formatHour(slot.hour);

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              child: InkWell(
                                onTap: () => _showSlotDetailsModal(
                                    context, slot, courtName),
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 38,
                                  child: Tooltip(
                                    message: slot.isAvailable
                                        ? '$labelText: Available (₹${slot.price.toStringAsFixed(0)}/hr)'
                                        : '${slot.formattedExactTimeRange}: ${slot.status} (${slot.title ?? "Occupied"})',
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: barColor.withValues(
                                                    alpha: 0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (slot.isBooked || slot.isPending)
                                          Positioned(
                                            top: 6,
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 3, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                slot.exactDurationMinutes !=
                                                        null
                                                    ? '${slot.exactDurationMinutes}m'
                                                    : '1h',
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 8),

                      // X-Axis Hour Labels aligned with bars
                      Row(
                        children: slots.map((slot) {
                          return SizedBox(
                            width: 44,
                            child: Text(
                              _formatHour(slot.hour),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        const Color(0xFF10B981), 'Available'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        const Color(0xFFEF4444), 'Booked'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        const Color(0xFFF59E0B), 'Pending'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        const Color(0xFF64748B), 'Closed'),
                  ],
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 16),

        // Hourly Grid List (Detailed Availability Timeline)
        Text(
          'Hourly Time Slots Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textPrimaryDark
                : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        Obx(() {
          if (controller.isScheduleLoading.value) {
            return const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            );
          }

          final activeCourt = controller.chartCourtId.value;
          final courtName = activeCourt == 'court_1' ? 'Court 1' : 'Court 2';
          final slots = controller.getSlotsForActiveCourt();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: slots.map((slot) {
                final timeLabel = _formatHourRange(slot.hour);

                Color statusColor;
                IconData statusIcon;
                String statusText;

                if (slot.isAvailable) {
                  statusColor = const Color(0xFF10B981);
                  statusIcon = Icons.check_circle_rounded;
                  statusText = 'Available';
                } else if (slot.isBooked) {
                  statusColor = const Color(0xFFEF4444);
                  statusIcon = Icons.lock_clock_rounded;
                  statusText = 'Booked';
                } else if (slot.isPending) {
                  statusColor = const Color(0xFFF59E0B);
                  statusIcon = Icons.timer_rounded;
                  statusText = 'Pending';
                } else {
                  statusColor = const Color(0xFF64748B);
                  statusIcon = Icons.block_rounded;
                  statusText = 'Closed';
                }

                return InkWell(
                  onTap: () {
                    if (slot.isAvailable) {
                      if (Get.isRegistered<ConnectivityService>() &&
                          !ConnectivityService.to.isConnected.value) {
                        ErrorHandler.showErrorSnackBar(
                          'No Internet Connection',
                          'Pitch booking requires an active internet connection.',
                        );
                        return;
                      }
                      Get.toNamed(Routes.createGame, arguments: {
                        'courtId': activeCourt,
                        'selectedDate': controller.chartSelectedDate.value,
                        'startTime': slot.startTime,
                        'endTime': slot.endTime,
                      });
                    } else {
                      ErrorHandler.showWarningSnackBar(
                        'Slot Occupied (${slot.formattedExactTimeRange})',
                        'This pitch slot is $statusText. Please select an available green slot.',
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slot.isBooked || slot.isPending
                              ? slot.formattedExactTimeRange
                              : '₹${slot.price.toStringAsFixed(0)}/hr',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: slot.isBooked
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: slot.isBooked
                                ? const Color(0xFFEF4444)
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  void _showSlotDetailsModal(
      BuildContext context, SlotAvailabilityItem slot, String courtName) {
    final timeLabel = _formatHourRange(slot.hour);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  slot.isAvailable
                      ? Icons.check_circle_rounded
                      : (slot.isBooked
                          ? Icons.lock_clock_rounded
                          : Icons.block_rounded),
                  color: slot.isAvailable
                      ? const Color(0xFF10B981)
                      : (slot.isBooked
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B)),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$courtName • $timeLabel Slot',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reserved Time Window:',
                    style: TextStyle(color: Colors.grey)),
                Text(
                  slot.formattedExactTimeRange,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Booking Duration:',
                    style: TextStyle(color: Colors.grey)),
                Text(
                  slot.formattedDurationText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pitch Status:', style: TextStyle(color: Colors.grey)),
                Text(
                  slot.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: slot.isAvailable
                        ? const Color(0xFF10B981)
                        : (slot.isBooked
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hourly Rate:', style: TextStyle(color: Colors.grey)),
                Text('₹${slot.price.toStringAsFixed(0)} / hr',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (slot.title != null && slot.title!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Title / Details:',
                      style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      slot.title!,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (slot.isBooked || slot.isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pitch Free Time:',
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    'Frees at ${AppDateUtils.formatTime(slot.exactEndTime ?? slot.endTime)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      slot.isAvailable ? AppColors.primary : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: slot.isAvailable
                    ? () {
                        Get.back();
                        Get.toNamed(Routes.createGame, arguments: {
                          'courtId': controller.chartCourtId.value,
                          'selectedDate': controller.chartSelectedDate.value,
                          'startTime': slot.startTime,
                          'endTime': slot.endTime,
                        });
                      }
                    : null,
                child: Text(
                  slot.isAvailable ? 'Book This Pitch Slot' : 'Slot Occupied',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _formatHourRange(int hour) {
    final start = _formatHour(hour);
    final end = _formatHour((hour + 1) % 24);
    return '$start - $end';
  }

  Widget _buildChartCourtTab(
      BuildContext context, String courtId, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = controller.chartCourtId.value == courtId;

    return InkWell(
      onTap: () => controller.setChartCourt(courtId),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildChartDateChip(
      BuildContext context, String filterKey, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = controller.chartDateFilter.value == filterKey;

    return InkWell(
      onTap: () => controller.setChartDateFilter(filterKey, context),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
