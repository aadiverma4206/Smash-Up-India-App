import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
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
                        const SizedBox(height: 16),
                        _buildCctvRecordingOptionCard(context, controller),
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
    if (!Get.isRegistered<ConnectivityService>()) {
      return const SizedBox.shrink();
    }
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
            const Icon(Icons.wifi_off_rounded,
                color: Colors.redAccent, size: 24),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() {
        final court = controller.selectedCourt.value;
        final sport = controller.selectedGameTitle.value;
        final courtName = court?.name ?? 'Court 1';
        final surface = court?.surfaceType ?? '3G Turf';
        final price = court?.basePricePerHour ?? 1200.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sport == 'Pickle'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sport == 'Pickle'
                            ? Icons.sports_tennis_rounded
                            : Icons.sports_tennis_outlined,
                        color: sport == 'Pickle'
                            ? AppColors.primary
                            : const Color(0xFF8B5CF6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$sport Pitch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                        Text(
                          courtName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Get.toNamed(Routes.bookSlot);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_horiz_rounded,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Surface: $surface',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${price.toStringAsFixed(0)} / hr',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, CreateGameController controller) {
    return _ModernScheduleCardWidget(
      controller: controller,
      showCustomTimePicker: _showCustomTimePicker,
      showCustomDatePicker: _showCustomDatePicker,
    );
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
              'e.g. Need warm-up bibs, extra pickle balls or padel balls, etc.',
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

  Widget _buildCctvRecordingOptionCard(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final isSelected = controller.recordVideoWithCctv.value;
      return InkWell(
        onTap: () => controller.recordVideoWithCctv.value = !isSelected,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.borderColor,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : context.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  color: isSelected ? AppColors.primary : context.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Record Video (CCTV)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+ ₹100',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pay ₹100 extra to record your match on court CCTV',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isSelected,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => controller.recordVideoWithCctv.value = val,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSummaryAndSubmitButton(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final court = controller.selectedCourt.value;
      final courtName = court?.name ?? 'Select Court';
      final totalAmount = controller.pitchBookingAmount;
      final duration = controller.durationMinutes;
      final hasDate = controller.selectedDate.value != null;
      final hasTime = controller.startTime.value != null &&
          controller.endTime.value != null;

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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.stadium_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
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
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasDate && hasTime
                                  ? '$duration mins (${(duration / 60.0).toStringAsFixed(1)} hrs)${controller.recordVideoWithCctv.value ? ' • +₹100 CCTV' : ''}'
                                  : 'Select booking date & time slot',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
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
                const SizedBox(width: 12),
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

              String buttonText;
              if (!isOnline) {
                buttonText = 'No Internet • Reconnect to Book';
              } else if (!hasDate) {
                buttonText = 'Select Booking Date';
              } else if (!hasTime) {
                buttonText = 'Select Start & End Time';
              } else if (court != null) {
                buttonText =
                    'Book ${controller.selectedGameTitle.value} (${court.name}) • ₹${totalAmount.toStringAsFixed(0)}';
              } else {
                buttonText = 'Select Pitch / Court to Book';
              }

              return AppButton(
                text: buttonText,
                isLoading:
                    controller.isLoading.value || controller.isProcessing.value,
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

class _ModernScheduleCardWidget extends StatefulWidget {
  final CreateGameController controller;
  final Future<TimeOfDay?> Function({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) showCustomTimePicker;
  final Future<DateTime?> Function({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) showCustomDatePicker;

  const _ModernScheduleCardWidget({
    required this.controller,
    required this.showCustomTimePicker,
    required this.showCustomDatePicker,
  });

  @override
  State<_ModernScheduleCardWidget> createState() =>
      __ModernScheduleCardWidgetState();
}

class __ModernScheduleCardWidgetState extends State<_ModernScheduleCardWidget> {
  final ScrollController _horizontalHeaderScroll = ScrollController();
  final ScrollController _horizontalBodyScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  bool _isSyncingScroll = false;
  bool _showCustomTimePickers = false;
  int _visibleDaysCount = 10;

  // Generate 1-hour slot start times from 6:00 AM to 11:00 PM (18 hourly slots)
  static final List<TimeOfDay> _matrixTimeSlots = List.generate(18, (index) {
    return TimeOfDay(hour: 6 + index, minute: 0);
  });

  void _loadNext10Days() {
    if (_visibleDaysCount >= 90) {
      ErrorHandler.showWarningSnackBar(
        'Maximum Limit Reached',
        'Pitch bookings can be made up to 90 days in advance.',
      );
      return;
    }
    setState(() {
      _visibleDaysCount = math.min(_visibleDaysCount + 10, 90);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalHeaderScroll.hasClients) {
        _horizontalHeaderScroll.animateTo(
          _horizontalHeaderScroll.offset + 220.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _horizontalHeaderScroll.addListener(() {
      if (!_isSyncingScroll) {
        _isSyncingScroll = true;
        if (_horizontalBodyScroll.hasClients) {
          _horizontalBodyScroll.jumpTo(_horizontalHeaderScroll.offset);
        }
        _isSyncingScroll = false;
      }
    });

    _horizontalBodyScroll.addListener(() {
      if (!_isSyncingScroll) {
        _isSyncingScroll = true;
        if (_horizontalHeaderScroll.hasClients) {
          _horizontalHeaderScroll.jumpTo(_horizontalBodyScroll.offset);
        }
        _isSyncingScroll = false;
      }
    });
  }

  void _handleSlotTap({
    required DateTime date,
    required TimeOfDay slotStart,
    required CreateGameController controller,
    required DateTime selectedDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    final isSameDate = date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    final tapHour = slotStart.hour;
    final tapEndHour = (tapHour + 1) % 24;

    bool isHourAvailable(int hour) {
      final startM = hour * 60;
      final endM = startM + 60;
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final slotStartDt = DateTime(date.year, date.month, date.day, hour, 0);

      if (isToday &&
          slotStartDt.isBefore(now.subtract(const Duration(minutes: 1)))) {
        return false;
      }

      final dateIsoStr = AppDateUtils.formatIsoDate(date);
      for (final occ in controller.occupiedCourtSlots) {
        if (occ.bookingDate.isNotEmpty && occ.bookingDate != dateIsoStr) {
          continue;
        }
        final sUpper = occ.status.toUpperCase();
        if (sUpper == 'CANCELLED' ||
            sUpper == 'REJECTED' ||
            sUpper == 'EXPIRED') {
          continue;
        }
        if (startM < occ.endMinutes && endM > occ.startMinutes) {
          return false;
        }
      }
      return true;
    }

    if (!isSameDate || startTime == null || endTime == null) {
      // Different date or no active selection: Select this single 1-hour slot
      controller.updateDate(date);
      controller.setSlotRange(
        slotStart,
        TimeOfDay(hour: tapEndHour, minute: 0),
      );
      return;
    }

    // Same date with active selection:
    final curStartHour = startTime.hour;
    var curEndHour = endTime.hour;
    if (curEndHour == 0 && curStartHour > 0) curEndHour = 24;

    // Case 1: Tapping inside already selected slot range [curStartHour .. curEndHour - 1]
    if (tapHour >= curStartHour && tapHour < curEndHour) {
      final totalSlots = curEndHour - curStartHour;

      if (totalSlots <= 1) {
        // Single slot selected: Tapping it again unselects / toggles it off!
        controller.setSlotRange(null, null);
        return;
      }

      if (tapHour == curStartHour) {
        // Tapped top/starting slot: REMOVE top slot! Keep curEndHour!
        controller.setSlotRange(
          TimeOfDay(hour: (curStartHour + 1) % 24, minute: 0),
          TimeOfDay(hour: curEndHour % 24, minute: 0),
        );
      } else if (tapHour == curEndHour - 1) {
        // Tapped bottom/ending slot: REMOVE bottom slot! Keep curStartHour!
        controller.setSlotRange(
          TimeOfDay(hour: curStartHour % 24, minute: 0),
          TimeOfDay(hour: (curEndHour - 1) % 24, minute: 0),
        );
      } else {
        // Tapped a middle slot: Trim range to end after tapped slot
        controller.setSlotRange(
          TimeOfDay(hour: curStartHour % 24, minute: 0),
          TimeOfDay(hour: (tapHour + 1) % 24, minute: 0),
        );
      }
      return;
    }

    // Case 2: Extending range
    int newStartHour = curStartHour;
    int newEndHour = curEndHour;

    if (tapHour < curStartHour) {
      newStartHour = tapHour;
    } else if (tapHour >= curEndHour) {
      newEndHour = tapHour + 1;
    }

    // Verify all slots in [newStartHour .. newEndHour - 1] are available
    bool rangeValid = true;
    for (int h = newStartHour; h < newEndHour; h++) {
      if (!isHourAvailable(h)) {
        rangeValid = false;
        break;
      }
    }

    if (rangeValid) {
      controller.setSlotRange(
        TimeOfDay(hour: newStartHour % 24, minute: 0),
        TimeOfDay(hour: newEndHour % 24, minute: 0),
      );
    } else {
      // Non-contiguous tap or hit booked/passed slot: Reset to tapped 1-hour slot
      controller.setSlotRange(
        slotStart,
        TimeOfDay(hour: tapEndHour, minute: 0),
      );
    }
  }

  @override
  void dispose() {
    _horizontalHeaderScroll.dispose();
    _horizontalBodyScroll.dispose();
    _verticalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final selectedDate = controller.selectedDate.value ?? todayDate;
      if (controller.selectedDate.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.selectedDate.value == null) {
            controller.updateDate(todayDate);
          }
        });
      }

      final startTime = controller.startTime.value;
      final endTime = controller.endTime.value;
      final duration = controller.durationMinutes;

      final courtRate =
          controller.selectedCourt.value?.basePricePerHour ?? 1200.0;
      final slotPrice = courtRate.round(); // Hourly slot price

      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      final isTabletScreen = screenWidth >= 600;

      final timeColumnWidth =
          isSmallScreen ? 78.0 : (isTabletScreen ? 96.0 : 86.0);
      final dateColumnWidth =
          isSmallScreen ? 84.0 : (isTabletScreen ? 104.0 : 92.0);
      final cellHeight = isSmallScreen ? 54.0 : (isTabletScreen ? 62.0 : 58.0);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MATRIX GRID TABLE (PERFECT ALIGNED ROWS & COLUMNS)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 1. STICKY DATES HEADER ROW
                    Container(
                      height: 48,
                      color: context.isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          // Left Top Corner Header Box
                          Container(
                            width: timeColumnWidth,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: context.borderColor),
                                bottom: BorderSide(color: context.borderColor),
                              ),
                            ),
                            child: const Icon(Icons.schedule_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          // Scrollable Date Columns Header
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _horizontalHeaderScroll,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Row(
                                children: List.generate(_visibleDaysCount + 1,
                                    (dIndex) {
                                  if (dIndex == _visibleDaysCount) {
                                    // NEXT 10 DAYS HEADER BUTTON
                                    return InkWell(
                                      onTap: _loadNext10Days,
                                      child: Container(
                                        width: dateColumnWidth,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          border: Border(
                                            right: BorderSide(
                                                color: context.borderColor),
                                            bottom: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2.0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Next 10d',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Icon(Icons.chevron_right_rounded,
                                                size: 16,
                                                color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final date =
                                      todayDate.add(Duration(days: dIndex));
                                  final isSelectedDate =
                                      date.year == selectedDate.year &&
                                          date.month == selectedDate.month &&
                                          date.day == selectedDate.day;

                                  String dayName =
                                      DateFormat('EEE').format(date);
                                  String dayNum = DateFormat('dd').format(date);
                                  if (dIndex == 0) dayName = 'Today';

                                  return InkWell(
                                    onTap: () => controller.updateDate(date),
                                    child: Container(
                                      width: dateColumnWidth,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelectedDate
                                            ? AppColors.primary
                                                .withValues(alpha: 0.15)
                                            : Colors.transparent,
                                        border: Border(
                                          right: BorderSide(
                                              color: context.borderColor),
                                          bottom: BorderSide(
                                            color: isSelectedDate
                                                ? AppColors.primary
                                                : context.borderColor,
                                            width: isSelectedDate ? 2.5 : 1.0,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dayName,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelectedDate
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelectedDate
                                                  ? AppColors.primary
                                                  : context.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            dayNum,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: isSelectedDate
                                                  ? AppColors.primary
                                                  : context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. SCROLLABLE MATRIX BODY (Time Column + Cells Grid)
                    SizedBox(
                      height: 340,
                      child: SingleChildScrollView(
                        controller: _verticalScroll,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FIXED TIME COLUMN (LEFT)
                            Container(
                              width: timeColumnWidth,
                              color: context.isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              child: Column(
                                children: List.generate(_matrixTimeSlots.length,
                                    (tIndex) {
                                  final slotTime = _matrixTimeSlots[tIndex];
                                  final isNight =
                                      slotTime.hour >= 18 || slotTime.hour < 6;
                                  final formattedTime =
                                      AppDateUtils.formatTime(slotTime);

                                  return Container(
                                    height: cellHeight,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                            color: context.borderColor),
                                        bottom: BorderSide(
                                            color: context.borderColor
                                                .withValues(alpha: 0.5)),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Icon(
                                          isNight
                                              ? Icons.nightlight_round
                                              : Icons.wb_sunny_rounded,
                                          size: 12,
                                          color: isNight
                                              ? const Color(0xFF8B5CF6)
                                              : const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // HORIZONTAL SCROLLABLE MATRIX CELLS (RIGHT)
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _horizontalBodyScroll,
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                child: Row(
                                  children: List.generate(_visibleDaysCount + 1,
                                      (dIndex) {
                                    if (dIndex == _visibleDaysCount) {
                                      // NEXT 10 DAYS BODY COLUMN BUTTON
                                      return InkWell(
                                        onTap: _loadNext10Days,
                                        child: Container(
                                          width: dateColumnWidth,
                                          height: _matrixTimeSlots.length *
                                              cellHeight,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.05),
                                            border: Border(
                                              right: BorderSide(
                                                  color: context.borderColor),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: AppColors.primary,
                                                    size: 20),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Next 10 Days',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tap to load',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: context.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final date =
                                        todayDate.add(Duration(days: dIndex));
                                    final dateIsoStr =
                                        AppDateUtils.formatIsoDate(date);
                                    final isToday = date.year == now.year &&
                                        date.month == now.month &&
                                        date.day == now.day;

                                    return Container(
                                      width: dateColumnWidth,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                              color: context.borderColor),
                                        ),
                                      ),
                                      child: Column(
                                        children: List.generate(
                                            _matrixTimeSlots.length, (tIndex) {
                                          final slotStart =
                                              _matrixTimeSlots[tIndex];
                                          final startM = slotStart.hour * 60 +
                                              slotStart.minute;
                                          final endM =
                                              startM + 60; // 1-hour interval

                                          final slotStartDt = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            slotStart.hour,
                                            slotStart.minute,
                                          );

                                          final isPast = isToday &&
                                              slotStartDt.isBefore(now.subtract(
                                                  const Duration(minutes: 1)));

                                          bool isBooked = false;
                                          for (final occ in controller
                                              .occupiedCourtSlots) {
                                            if (occ.bookingDate.isNotEmpty &&
                                                occ.bookingDate != dateIsoStr) {
                                              continue;
                                            }
                                            final sUpper =
                                                occ.status.toUpperCase();
                                            if (sUpper == 'CANCELLED' ||
                                                sUpper == 'REJECTED' ||
                                                sUpper == 'EXPIRED') {
                                              continue;
                                            }
                                            if (startM < occ.endMinutes &&
                                                endM > occ.startMinutes) {
                                              isBooked = true;
                                              break;
                                            }
                                          }

                                          final isSameDate =
                                              date.year == selectedDate.year &&
                                                  date.month ==
                                                      selectedDate.month &&
                                                  date.day == selectedDate.day;

                                          bool isSelected = false;
                                          if (isSameDate &&
                                              startTime != null &&
                                              endTime != null) {
                                            final curStartM =
                                                startTime.hour * 60 +
                                                    startTime.minute;
                                            var curEndM = endTime.hour * 60 +
                                                endTime.minute;
                                            if (curEndM <= curStartM) {
                                              curEndM += 24 * 60;
                                            }
                                            if (startM < curEndM &&
                                                endM > curStartM) {
                                              isSelected = true;
                                            }
                                          }

                                          return _buildMatrixCell(
                                            context: context,
                                            controller: controller,
                                            date: date,
                                            slotStart: slotStart,
                                            isPast: isPast,
                                            isBooked: isBooked,
                                            isSelected: isSelected,
                                            slotPrice: slotPrice,
                                            cellHeight: cellHeight,
                                            onTapSlot: () => _handleSlotTap(
                                              date: date,
                                              slotStart: slotStart,
                                              controller: controller,
                                              selectedDate: selectedDate,
                                              startTime: startTime,
                                              endTime: endTime,
                                            ),
                                          );
                                        }),
                                      ),
                                    );
                                  }),
                                ),
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

            const SizedBox(height: 12),
            _buildCustomTimeToggle(context, controller, startTime, endTime),

            if (controller.isSelectedTimeInPast) ...[
              const SizedBox(height: 10),
              _buildPastTimeWarning(context, controller),
            ],

            if (controller.slotConflictWarning.value != null) ...[
              const SizedBox(height: 10),
              _buildConflictWarning(context, controller),
            ],

            const SizedBox(height: 10),
            _buildSlotSummaryBar(context, controller, selectedDate, duration),
          ],
        ),
      );
    });
  }

  Widget _buildMatrixCell({
    required BuildContext context,
    required CreateGameController controller,
    required DateTime date,
    required TimeOfDay slotStart,
    required bool isPast,
    required bool isBooked,
    required bool isSelected,
    required int slotPrice,
    required double cellHeight,
    required VoidCallback onTapSlot,
  }) {
    // 1. PASSED / EXPIRED SLOT (Sleek Rounded Blank Box UI)
    if (isPast) {
      return InkWell(
        onTap: () {
          ErrorHandler.showWarningSnackBar(
            'Past Time Slot',
            'This slot has already passed and cannot be booked.',
          );
        },
        child: Container(
          height: cellHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
              right:
                  BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: context.isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB),
                width: 0.6,
              ),
            ),
          ),
        ),
      );
    }

    // 2. BOOKED / OCCUPIED SLOT (Light Red Box with Red Price Text)
    if (isBooked) {
      return InkWell(
        onTap: () {
          ErrorHandler.showWarningSnackBar(
            'Slot Booked',
            'This slot is already booked. Please select another slot.',
          );
        },
        child: Container(
          height: cellHeight,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF450A0A)
                : const Color(0xFFFEE2E2), // Light Red Box
            border: Border(
              bottom:
                  BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
              right:
                  BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹ $slotPrice',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626), // Red Bold Text
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 1),
              const Text(
                'Booked',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. SELECTED SLOT (Green Accent Fill + 2.0px Green Border)
    if (isSelected) {
      return InkWell(
        onTap: onTapSlot,
        child: Container(
          height: cellHeight,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF064E3B)
                : const Color(0xFFDCFCE7),
            border: Border.all(color: AppColors.primary, width: 2.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹ $slotPrice',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 1),
              const Text(
                'Selected',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. AVAILABLE SLOT (White Box with Price & '1 left' subtext)
    return InkWell(
      onTap: onTapSlot,
      child: Container(
        height: cellHeight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            bottom:
                BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
            right:
                BorderSide(color: context.borderColor.withValues(alpha: 0.4)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹ $slotPrice',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 1),
            Text(
              '1 left',
              style: TextStyle(
                fontSize: 8.5,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimeToggle(
    BuildContext context,
    CreateGameController controller,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  ) {
    final currentDuration = controller.durationMinutes;

    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showCustomTimePickers = !_showCustomTimePickers),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need custom start/end time or duration?',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _showCustomTimePickers
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_showCustomTimePickers) ...[
          const SizedBox(height: 10),
          // Quick Duration Presets
          Row(
            children: [
              Text(
                'Quick Duration:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildDurationChip(
                          controller, '1 hr', 60, currentDuration),
                      const SizedBox(width: 6),
                      _buildDurationChip(
                          controller, '1.5 hrs', 90, currentDuration),
                      const SizedBox(width: 6),
                      _buildDurationChip(
                          controller, '2 hrs', 120, currentDuration),
                      const SizedBox(width: 6),
                      _buildDurationChip(
                          controller, '3 hrs', 180, currentDuration),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await widget.showCustomTimePicker(
                      context: context,
                      initialTime:
                          startTime ?? const TimeOfDay(hour: 18, minute: 0),
                    );
                    if (picked != null) controller.updateStartTime(picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Time',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      color: context.textSecondary)),
                              Text(
                                startTime != null
                                    ? AppDateUtils.formatTime(startTime)
                                    : 'Select Start',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await widget.showCustomTimePicker(
                      context: context,
                      initialTime:
                          endTime ?? const TimeOfDay(hour: 19, minute: 30),
                    );
                    if (picked != null) controller.updateEndTime(picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Time',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      color: context.textSecondary)),
                              Text(
                                endTime != null
                                    ? AppDateUtils.formatTime(endTime)
                                    : 'Select End',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDurationChip(
    CreateGameController controller,
    String label,
    int minutes,
    int currentDuration,
  ) {
    final isSelected = currentDuration == minutes;
    return InkWell(
      onTap: () => controller.setDurationInMinutes(minutes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPastTimeWarning(
      BuildContext context, CreateGameController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Past Time Slot Selected',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Selected start time (${controller.startTime.value != null ? AppDateUtils.formatTime(controller.startTime.value!) : ""}) has already passed.',
                      style:
                          TextStyle(color: context.textPrimary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.setToNextAvailableHour(),
              icon: const Icon(Icons.bolt_rounded, size: 14),
              label: const Text(
                'Set To Next Available Upcoming Hour',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictWarning(
      BuildContext context, CreateGameController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  controller.slotConflictWarning.value ?? '',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (controller.availableCourts.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.switchToAlternateCourt(),
                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                label: const Text(
                  'Switch to Alternate Available Court',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotSummaryBar(BuildContext context,
      CreateGameController controller, DateTime selectedDate, int duration) {
    final startTime = controller.startTime.value;
    final endTime = controller.endTime.value;

    final dateFormatted = DateFormat('dd MMM yyyy').format(selectedDate);
    final startFormatted =
        startTime != null ? AppDateUtils.formatTime(startTime) : 'Select Start';
    final endFormatted =
        endTime != null ? AppDateUtils.formatTime(endTime) : 'Select End';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateFormatted  •  $startFormatted - $endFormatted',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Duration: $duration mins (${(duration / 60.0).toStringAsFixed(1)} hrs)',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
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
