import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_game_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/responsive/responsive_builder.dart';

class CreateGameView extends StatelessWidget {
  const CreateGameView({super.key});

  static Future<TimeOfDay?> _showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (BuildContext context, Widget? child) {
        final mediaQuery = MediaQuery.of(context);
        final dialogWidth = math.min(mediaQuery.size.width * 0.9, 360.0);

        return MediaQuery(
          data: mediaQuery.copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: context.cardColor,
                    onSurface: context.textPrimary,
                    surfaceContainerHighest:
                        AppColors.primary.withValues(alpha: 0.12),
                  ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: context.cardColor,
                hourMinuteColor: AppColors.primary.withValues(alpha: 0.15),
                hourMinuteTextColor: AppColors.primary,
                dayPeriodColor: AppColors.primary.withValues(alpha: 0.15),
                dayPeriodTextColor: AppColors.primary,
                dayPeriodBorderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
                dialHandColor: AppColors.primary,
                dialBackgroundColor: context.backgroundColor,
                dialTextColor: context.textPrimary,
                entryModeIconColor: AppColors.primary,
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

  static Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        final mediaQuery = MediaQuery.of(context);
        final dialogWidth = math.min(mediaQuery.size.width * 0.9, 360.0);

        return MediaQuery(
          data: mediaQuery.copyWith(
            alwaysUse24HourFormat: false,
          ),
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
    final controller = Get.put(CreateGameController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Football Game',
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
                        _buildSectionHeader(
                          context,
                          title: 'Club & Pitch Info',
                          icon: Icons.stadium_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildVenueSelectionCard(context, controller),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'Match Details & Entry Fee',
                          icon: Icons.sports_soccer_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildMatchDetailsCard(context, controller),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'Match Date & Timing',
                          icon: Icons.calendar_month_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildScheduleCard(context, controller),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'Guidelines & Description',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Club Name *',
                prefixIcon:
                    const Icon(Icons.business_rounded, color: AppColors.primary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor, width: 1.2),
                ),
              ),
              child: Text(
                controller.selectedClub.value.name.isNotEmpty
                    ? controller.selectedClub.value.name
                    : 'All Stars Turf Raipur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
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
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: courts.map((court) {
                final isSelected = selectedCourt?.id == court.id ||
                    selectedCourt?.name == court.name;
                return InkWell(
                  onTap: () {
                    controller.selectedCourt.value = court;
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : context.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.borderColor,
                        width: isSelected ? 1.8 : 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : context.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          court.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : context.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMatchDetailsCard(
      BuildContext context, CreateGameController controller) {
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
            'Game Type / Format *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: controller.formats.map((fmt) {
                  final isSelected = controller.selectedFormat.value == fmt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        fmt,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: context.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : context.borderColor,
                        ),
                      ),
                      onSelected: (_) => controller.setFormat(fmt),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 8),
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max Players: ${controller.maxPlayers.value} (${controller.maxPlayers.value ~/ 2} vs ${controller.maxPlayers.value ~/ 2})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.titleController,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Match Title *',
              hintText: 'e.g. Sunday Football Showdown',
              prefixIcon:
                  const Icon(Icons.title_rounded, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Match title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.entryFeeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Entry Fee Per Player (₹) *',
              hintText: 'e.g. 200',
              prefixIcon:
                  const Icon(Icons.currency_rupee, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Entry fee is required';
              }
              final fee = double.tryParse(val.trim());
              if (fee == null || fee < 0) {
                return 'Enter a valid non-negative entry fee';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Obx(
            () => TextFormField(
              controller: controller.reservePlayersController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: context.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Extra Reserve / Substitute Players Count *',
                hintText: 'e.g. 2',
                prefixIcon: const Icon(Icons.person_add_alt_1_rounded,
                    color: AppColors.primary),
                helperText:
                    'Extra players on reserve bench (e.g. 2 reserves = ${controller.maxPlayers.value + (int.tryParse(controller.reserveCountRx.value) ?? 0)} total capacity)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.borderColor, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Reserve count is required';
                }
                final count = int.tryParse(val.trim());
                if (count == null || count < 0 || count > 10) {
                  return 'Enter a valid count (0 to 10)';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.skillRequirement.value,
              hint: Text('Select Skill Level',
                  style: TextStyle(color: context.textSecondary, fontSize: 14)),
              dropdownColor: context.cardColor,
              style: TextStyle(color: context.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Required Skill Level *',
                prefixIcon:
                    const Icon(Icons.star_rounded, color: AppColors.primary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.borderColor, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              items: controller.skills.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s),
                );
              }).toList(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please select required skill level';
                }
                return null;
              },
              onChanged: (val) {
                if (val != null) controller.skillRequirement.value = val;
              },
            ),
          ),
          const SizedBox(height: 14),
          Text('Match Privacy',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final isPublic = controller.privacy.value == 'PUBLIC';
                  return ChoiceChip(
                    label: Center(
                      child: Text('Public Lobby',
                          style: TextStyle(
                              color: isPublic
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                    selected: isPublic,
                    selectedColor: AppColors.primary,
                    backgroundColor: context.backgroundColor,
                    onSelected: (selected) {
                      if (selected) controller.privacy.value = 'PUBLIC';
                    },
                  );
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() {
                  final isPrivate = controller.privacy.value == 'PRIVATE';
                  return ChoiceChip(
                    label: Center(
                      child: Text('Private Match',
                          style: TextStyle(
                              color: isPrivate
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                    selected: isPrivate,
                    selectedColor: AppColors.primary,
                    backgroundColor: context.backgroundColor,
                    onSelected: (selected) {
                      if (selected) controller.privacy.value = 'PRIVATE';
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, CreateGameController controller) {
    return Obx(() {
      final selectedDate = controller.selectedDate.value;
      final startTime = controller.startTime.value;
      final endTime = controller.endTime.value;

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
              'Match Date *',
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
                  initialDate:
                      selectedDate ?? DateTime.now().add(const Duration(days: 1)),
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
                            : 'Tap to select match date',
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
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
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
                                    fontSize: 14,
                                  ),
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
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
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
                                    fontSize: 14,
                                  ),
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
                } else {
                  return Row(
                    children: [
                      Expanded(child: buildStartTimeWidget()),
                      const SizedBox(width: 12),
                      Expanded(child: buildEndTimeWidget()),
                    ],
                  );
                }
              },
            ),
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
          labelText: 'Match Rules & Extra Details (Optional)',
          hintText:
              'e.g. Bring black & white jerseys. Standard rules apply.',
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
      final fee = controller.entryFeeRx.value.isEmpty
          ? '0'
          : controller.entryFeeRx.value;
      final reserves = controller.reserveCountRx.value.isEmpty
          ? '0'
          : controller.reserveCountRx.value;
      final fmt = controller.selectedFormat.value;
      final mainCount = controller.maxPlayers.value;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$fmt ($mainCount Main + $reserves Subs)',
                      style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '₹$fee / player',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButton(
              text: 'Create $fmt Football Game',
              isLoading: controller.isLoading.value,
              onPressed: controller.proceedToCheckout,
            ),
          ),
        ],
      );
    });
  }
}
