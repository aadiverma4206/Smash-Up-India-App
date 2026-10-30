import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_game_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/error_handler.dart';

class CreateGameView extends StatelessWidget {
  const CreateGameView({super.key});

  Future<TimeOfDay?> _showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        final mediaQuery = MediaQuery.of(context);
        final dialogWidth = math.min(mediaQuery.size.width * 0.9, 360.0);

        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: context.cardColor,
                    onSurface: context.textPrimary,
                  ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: context.cardColor,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.borderColor, width: 1),
                ),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: context.borderColor, width: 1),
                ),
                dayPeriodBorderSide:
                    BorderSide(color: context.borderColor, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: context.borderColor, width: 1),
                ),
                dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return context.textPrimary;
                }),
                dayPeriodColor: WidgetStateColor.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return context.backgroundColor;
                }),
              ),
            ),
            child: Center(
              child: UnconstrainedBox(
                child: SizedBox(
                  width: dialogWidth,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        final mediaQuery = MediaQuery.of(context);
        final dialogWidth = math.min(mediaQuery.size.width * 0.9, 360.0);

        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: context.cardColor,
                    onSurface: context.textPrimary,
                  ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: context.cardColor,
                headerBackgroundColor: AppColors.primary,
                headerForegroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                dayStyle: TextStyle(color: context.textPrimary),
                weekdayStyle: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
                yearStyle: TextStyle(color: context.textPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: context.borderColor, width: 1),
                ),
              ),
            ),
            child: Center(
              child: UnconstrainedBox(
                child: SizedBox(
                  width: dialogWidth,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CreateGameController>()
        ? Get.find<CreateGameController>()
        : Get.put(CreateGameController(), permanent: true);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Pitch',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop = deviceType == DeviceType.desktop ||
              deviceType == DeviceType.tablet;
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final maxContainerWidth =
              (isTabletOrDesktop || isLandscape) ? 680.0 : double.infinity;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContainerWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 18,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOfflineWarningBanner(context),
                        _buildSectionHeader(
                          context,
                          title: 'Sport & Pitch Info',
                          icon: Icons.sports_soccer_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildVenueSelectionCard(context, controller),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'Pitch Booking Date & Time Slot',
                          icon: Icons.calendar_month_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildScheduleCard(context, controller),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'Notes',
                          icon: Icons.description_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildRulesCard(context, controller),
                        const SizedBox(height: 24),
                        _buildSummaryAndSubmitButton(context, controller),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineWarningBanner(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return const SizedBox.shrink();
    return Obx(() {
      final isOnline = ConnectivityService.to.isConnected.value;
      if (isOnline) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pitch booking, court slot checks, and checkout require an active internet connection.',
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueSelectionCard(
      BuildContext context, CreateGameController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Obx(() {
        final courts = controller.availableCourts;
        final selectedCourt = controller.selectedCourt.value;
        final selectedTitle = controller.selectedGameTitle.value;

        final sports = [
          {
            'name': 'Football',
            'subtitle': 'Turf Pitch',
          },
          {
            'name': 'Basketball',
            'subtitle': 'Standard Court',
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Sport / Game Title *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: sports.map((sport) {
                    final sportName = sport['name']!;
                    final sportSubtitle = sport['subtitle']!;
                    final isSelected =
                        selectedTitle.toLowerCase() == sportName.toLowerCase();

                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () {
                          controller.selectedGameTitle.value = sportName;
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : context.backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: isSelected
                                    ? AppColors.primary
                                    : context.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sportName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : context.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      sportSubtitle,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : context.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Select Pitch / Court *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final itemWidth = courts.length >= 2
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: courts.map((court) {
                    final isSelected = selectedCourt?.id == court.id ||
                        selectedCourt?.name == court.name;
                    final cStatus = court.status.toUpperCase();
                    final isDisabled =
                        cStatus == 'MAINTENANCE' || cStatus == 'BLOCKED';

                    return SizedBox(
                      width: itemWidth,
                      child: Opacity(
                        opacity: isDisabled ? 0.55 : 1.0,
                        child: InkWell(
                          onTap: isDisabled
                              ? () {
                                  ErrorHandler.showWarningSnackBar(
                                    'Court Unavailable',
                                    '${court.name} is currently in $cStatus status and cannot be selected.',
                                  );
                                }
                              : () {
                                  controller.selectCourt(court);
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? (isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade200)
                                  : (isSelected
                                      ? AppColors.primary
                                          .withValues(alpha: 0.12)
                                      : context.backgroundColor),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDisabled
                                    ? Colors.grey.shade400
                                    : (isSelected
                                        ? AppColors.primary
                                        : context.borderColor),
                                width: isSelected && !isDisabled ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDisabled
                                      ? Icons.block_rounded
                                      : (isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded),
                                  size: 18,
                                  color: isDisabled
                                      ? Colors.grey.shade500
                                      : (isSelected
                                          ? AppColors.primary
                                          : context.textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        court.name,
                                        style: TextStyle(
                                          color: isDisabled
                                              ? Colors.grey.shade500
                                              : (isSelected
                                                  ? AppColors.primary
                                                  : context.textPrimary),
                                          fontWeight: isSelected && !isDisabled
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isDisabled
                                            ? (cStatus == 'MAINTENANCE'
                                                ? 'Maintenance'
                                                : 'Blocked')
                                            : '${court.surfaceType} • ₹${court.basePricePerHour.toStringAsFixed(0)}/hr',
                                        style: TextStyle(
                                          color: isDisabled
                                              ? (cStatus == 'MAINTENANCE'
                                                  ? Colors.amber.shade800
                                                  : Colors.redAccent)
                                              : context.textSecondary,
                                          fontSize: 10,
                                          fontWeight: isDisabled
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final selectedDate = controller.selectedDate.value;
      final startTime = controller.startTime.value;
      final endTime = controller.endTime.value;
      final duration = controller.durationMinutes;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Date *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await _showCustomDatePicker(
                  context: context,
                  initialDate: selectedDate ??
                      DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) controller.updateDate(picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? AppDateUtils.formatDate(selectedDate,
                                format: 'EEEE, dd MMMM yyyy')
                            : 'Tap to select booking date',
                        style: TextStyle(
                          color: selectedDate != null
                              ? context.textPrimary
                              : context.textSecondary,
                          fontWeight: selectedDate != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: context.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 280;

                Widget buildStartTimeWidget() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await _showCustomTimePicker(
                            context: context,
                            initialTime: startTime ??
                                const TimeOfDay(hour: 18, minute: 0),
                          );
                          if (picked != null) {
                            controller.updateStartTime(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: context.borderColor, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                startTime != null
                                    ? AppDateUtils.formatTime(startTime)
                                    : 'Select Start',
                                style: TextStyle(
                                  color: startTime != null
                                      ? context.textPrimary
                                      : context.textSecondary,
                                  fontWeight: startTime != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                Widget buildEndTimeWidget() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await _showCustomTimePicker(
                            context: context,
                            initialTime: endTime ??
                                const TimeOfDay(hour: 19, minute: 30),
                          );
                          if (picked != null) {
                            controller.updateEndTime(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: context.borderColor, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                endTime != null
                                    ? AppDateUtils.formatTime(endTime)
                                    : 'Select End',
                                style: TextStyle(
                                  color: endTime != null
                                      ? context.textPrimary
                                      : context.textSecondary,
                                  fontWeight: endTime != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (isNarrow) {
                  return Column(
                    children: [
                      buildStartTimeWidget(),
                      const SizedBox(height: 12),
                      buildEndTimeWidget(),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: buildStartTimeWidget()),
                    const SizedBox(width: 12),
                    Expanded(child: buildEndTimeWidget()),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Booking Duration: $duration Minutes (${(duration / 60.0).toStringAsFixed(1)} hrs)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Past Time Warning Card
            if (controller.isSelectedTimeInPast) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.history_toggle_off_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Past Time Slot Selected',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'You cannot book a game in the past. The selected start time (${controller.startTime.value != null ? AppDateUtils.formatTime(controller.startTime.value!) : ""}) has already passed today.',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => controller.setToNextAvailableHour(),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text(
                          'Set To Next Available Upcoming Hour',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Slot Collision Warning & Resolution Card
            if (controller.slotConflictWarning.value != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Court Slot Collision Detected',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                controller.slotConflictWarning.value!,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                controller.switchToAlternateCourt(),
                            icon:
                                const Icon(Icons.swap_horiz_rounded, size: 14),
                            label: Text(
                              controller.selectedCourt.value?.name
                                          .contains('2') ==
                                      true
                                  ? 'Switch to Court 1'
                                  : 'Switch to Court 2',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (controller.conflictingSlot.value != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final parts = controller
                                    .conflictingSlot.value!.endTime
                                    .split(':');
                                if (parts.length >= 2) {
                                  final h = int.tryParse(parts[0]) ?? 0;
                                  final m = int.tryParse(parts[1]) ?? 0;
                                  controller.updateStartTime(
                                      TimeOfDay(hour: h, minute: m));
                                }
                              },
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 14),
                              label: Text(
                                'Start at ${controller.conflictingSlot.value!.endTime}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildRulesCard(
      BuildContext context, CreateGameController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: TextFormField(
        controller: controller.descriptionController,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: 'Pitch Booking Notes & Special Requests (Optional)',
          hintText:
              'e.g. Need warm-up bibs, extra footballs or basketballs, etc.',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryAndSubmitButton(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final court = controller.selectedCourt.value;
      final courtName = court?.name ?? 'Select Court';
      final totalAmount = controller.pitchBookingAmount;
      final duration = controller.durationMinutes;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stadium_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court != null
                              ? '${controller.selectedGameTitle.value} • $courtName'
                              : controller.selectedGameTitle.value,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$duration mins (${(duration / 60.0).toStringAsFixed(1)} hrs)',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(() {
              final isOnline = Get.isRegistered<ConnectivityService>()
                  ? ConnectivityService.to.isConnected.value
                  : true;

              return AppButton(
                text: !isOnline
                    ? 'No Internet • Reconnect to Book'
                    : court != null
                        ? 'Book ${controller.selectedGameTitle.value} (${court.name}) • ₹${totalAmount.toStringAsFixed(0)}'
                        : 'Select Pitch / Court to Book',
                isLoading: controller.isLoading.value || controller.isProcessing.value,
                onPressed: () {
                  if (!isOnline) {
                    ErrorHandler.showErrorSnackBar(
                      'No Internet Connection',
                      'Cannot book pitch without an active internet connection. Please turn on mobile data or Wi-Fi to proceed.',
                    );
                    return;
                  }
                  controller.proceedToCheckout();
                },
              );
            }),
          ),
        ],
      );
    });
  }
}
