import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/courts_controller.dart';
import '../../../data/models/court_model.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/error_handler.dart';

class CourtsListView extends GetView<CourtsController> {
  const CourtsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Available Courts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SkeletonContainer(
                    width: double.infinity, height: 120, borderRadius: 20),
                SizedBox(height: 16),
                Expanded(child: SkeletonListLoader(count: 3)),
              ],
            ),
          );
        }

        final filteredList = controller.filteredCourts;

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchCourts();
            await controller
                .fetchScheduleForDate(controller.chartSelectedDate.value);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Centered Search & Filter Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Inside Card
                    TextField(
                      onChanged: (val) => controller.setSearchQuery(val),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search court name, turf or city...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.primary),
                        suffixIcon:
                            Obx(() => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    onPressed: () =>
                                        controller.setSearchQuery(''),
                                  )
                                : const SizedBox.shrink()),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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

                    const SizedBox(height: 12),

                    // Filter Status Label
                    Text(
                      'Filter By Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            label: 'All (${controller.totalCount})',
                            statusKey: 'ALL',
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            context,
                            label: 'Available (${controller.availableCount})',
                            statusKey: 'AVAILABLE',
                            activeColor: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            context,
                            label:
                                'Maintenance (${controller.maintenanceCount})',
                            statusKey: 'MAINTENANCE',
                            activeColor: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            context,
                            label: 'Blocked (${controller.blockedCount})',
                            statusKey: 'BLOCKED',
                            activeColor: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Courts List Header
              Row(
                children: [
                  const Icon(Icons.stadium_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Court Pitches (${filteredList.length})',
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

              const SizedBox(height: 12),

              // Courts Cards List
              if (filteredList.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyStateWidget(
                    title: 'No Courts Found',
                    subtitle:
                        'No courts match your selected status filter or search query.',
                    icon: Icons.stadium_outlined,
                  ),
                )
              else
                ...filteredList.map((court) => _buildCourtCard(context, court)),

              // Court Hourly Availability Chart & Schedule Timeline Section
              _buildAvailabilityChartSection(context),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String statusKey,
    required Color activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = controller.selectedStatusFilter.value == statusKey;

    return InkWell(
      onTap: () => controller.setStatusFilter(statusKey),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, CourtModel court) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Accent Bar
              Container(
                width: 4,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Court Title & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.20),
                                  AppColors.primary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.stadium_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withValues(
                                              alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (court.clubName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${court.clubName}${court.city.isNotEmpty ? ' • ${court.city}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Price & Booking Action
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hourly Price',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${court.basePricePerHour.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.primary
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/ hour',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: isAvailable
                                  ? () {
                                      if (Get.isRegistered<ConnectivityService>() &&
                                          !ConnectivityService.to.isConnected.value) {
                                        ErrorHandler.showErrorSnackBar(
                                          'No Internet Connection',
                                          'Pitch booking requires an active internet connection. Please turn on mobile data or Wi-Fi to proceed.',
                                        );
                                        return;
                                      }
                                      Get.toNamed(Routes.createGame,
                                          arguments: {'courtId': court.id});
                                    }
                                  : null,
                              icon: Icon(
                                isAvailable
                                    ? Icons.sports_soccer_rounded
                                    : Icons.block_rounded,
                                size: 15,
                              ),
                              label: Text(
                                isAvailable ? 'Book Pitch' : 'Unavailable',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAvailable
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.withValues(alpha: 0.2),
                                disabledForegroundColor: Colors.grey,
                                elevation: 0,
                                shadowColor: Colors.transparent,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            int bookedCount = 0;
            int freeCount = 0;

            final hoursList = List.generate(18, (index) => index + 6);
            for (final h in hoursList) {
              if (controller.getBookingForHour(h, activeCourt) != null) {
                bookedCount++;
              } else {
                freeCount++;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Stats inside Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${activeCourt == 'court_1' ? 'Court 1' : 'Court 2'} Status Chart',
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Bar Graph Visualization
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: hoursList.map((hour) {
                      final booking =
                          controller.getBookingForHour(hour, activeCourt);
                      final isBooked = booking != null;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Tooltip(
                            message: isBooked
                                ? '${_formatHour(hour)}: Booked (${booking['title'] ?? 'Match'})'
                                : '${_formatHour(hour)}: Available / Free',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: isBooked ? 90.0 : 40.0,
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isBooked
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981))
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
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

                // X-Axis Hour Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('6 am',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('9 am',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('12 pm',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('3 pm',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('6 pm',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('9 pm',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
                    Text('11 pm',
                        style: TextStyle(fontSize: 10, color: Colors.white60)),
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
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        Obx(() {
          final activeCourt = controller.chartCourtId.value;
          final hoursList = List.generate(18, (index) => index + 6);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: hoursList.map((hour) {
                final booking = controller.getBookingForHour(hour, activeCourt);
                final isBooked = booking != null;
                final timeLabel = _formatHourRange(hour);

                return InkWell(
                  onTap: () {
                    if (!isBooked) {
                      if (Get.isRegistered<ConnectivityService>() &&
                          !ConnectivityService.to.isConnected.value) {
                        ErrorHandler.showErrorSnackBar(
                          'No Internet Connection',
                          'Pitch booking requires an active internet connection. Please turn on mobile data or Wi-Fi to proceed.',
                        );
                        return;
                      }
                      Get.toNamed(Routes.createGame, arguments: {
                        'courtId': activeCourt,
                        'startTime': '${hour.toString().padLeft(2, '0')}:00',
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBooked
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isBooked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isBooked
                                  ? Icons.lock_clock_rounded
                                  : Icons.check_circle_rounded,
                              size: 12,
                              color: isBooked
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBooked ? 'Booked' : 'Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isBooked
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
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
