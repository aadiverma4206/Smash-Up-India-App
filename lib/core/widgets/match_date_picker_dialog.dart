import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../utils/app_date_utils.dart';

/// Opens a custom Date Picker dialog that highlights upcoming match dates with a blue tick badge
/// and past/completed match dates with a green tick badge.
Future<DateTime?> showMatchDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  Set<String>? matchDates,
  Set<String>? upcomingMatchDates,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => MatchDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      matchDates: matchDates,
      upcomingMatchDates: upcomingMatchDates,
    ),
  );
}

class MatchDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<String>? matchDates;
  final Set<String>? upcomingMatchDates;

  const MatchDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.matchDates,
    this.upcomingMatchDates,
  });

  @override
  State<MatchDatePickerDialog> createState() => _MatchDatePickerDialogState();
}

class _MatchDatePickerDialogState extends State<MatchDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late DateTime _startMonth;
  late DateTime _endMonth;
  late int _totalMonths;
  late PageController _pageController;
  late Set<String> _normalizedMatchDates;
  late Set<String> _normalizedUpcomingMatchDates;
  bool _isYearPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _startMonth = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    _endMonth = DateTime(widget.lastDate.year, widget.lastDate.month, 1);
    _totalMonths = (_endMonth.year - _startMonth.year) * 12 +
        (_endMonth.month - _startMonth.month) +
        1;
    if (_totalMonths < 1) _totalMonths = 1;

    final initialMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    int initialPage = (initialMonth.year - _startMonth.year) * 12 +
        (initialMonth.month - _startMonth.month);
    if (initialPage < 0) initialPage = 0;
    if (initialPage >= _totalMonths) initialPage = _totalMonths - 1;

    _pageController = PageController(initialPage: initialPage);
    _displayedMonth = DateTime(
      _startMonth.year,
      _startMonth.month + initialPage,
      1,
    );

    _normalizeMatchDates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _normalizeMatchDates() {
    _normalizedMatchDates = <String>{};
    if (widget.matchDates != null) {
      for (final raw in widget.matchDates!) {
        final dt = AppDateUtils.parseDate(raw);
        if (dt != null) {
          final formatted =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          _normalizedMatchDates.add(formatted);
        }
      }
    }

    _normalizedUpcomingMatchDates = <String>{};
    if (widget.upcomingMatchDates != null) {
      for (final raw in widget.upcomingMatchDates!) {
        final dt = AppDateUtils.parseDate(raw);
        if (dt != null) {
          final formatted =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          _normalizedUpcomingMatchDates.add(formatted);
        }
      }
    }
  }

  bool get _canGoToPreviousMonth {
    final lastDayOfPrevMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 0);
    return !lastDayOfPrevMonth.isBefore(widget.firstDate);
  }

  bool get _canGoToNextMonth {
    final nextMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    return !nextMonth.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 330,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: dialogBg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select date',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('EEE, MMM d').format(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(
                        _isYearPicker
                            ? Icons.calendar_today_rounded
                            : Icons.edit_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _isYearPicker = !_isYearPicker;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (_isYearPicker)
              _buildYearMonthPicker(isDark)
            else
              _buildCalendarPicker(isDark),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.only(
                  right: 16, bottom: 12, top: 4, left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPicker(bool isDark) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation bar
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isYearPicker = true;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _canGoToPreviousMonth
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _canGoToNextMonth
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Labels
          Row(
            children: weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Swipeable Calendar Days Grid
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalMonths,
              onPageChanged: (pageIndex) {
                setState(() {
                  _displayedMonth = DateTime(
                    _startMonth.year,
                    _startMonth.month + pageIndex,
                    1,
                  );
                });
              },
              itemBuilder: (context, pageIndex) {
                final monthDate = DateTime(
                  _startMonth.year,
                  _startMonth.month + pageIndex,
                  1,
                );
                return _buildMonthGrid(monthDate, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(DateTime monthDate, bool isDark) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadingEmptySlots = firstDayOfMonth.weekday % 7;
    final totalGridItems = leadingEmptySlots + daysInMonth;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalGridItems,
      itemBuilder: (context, index) {
        if (index < leadingEmptySlots) {
          return const SizedBox();
        }
        final dayNum = index - leadingEmptySlots + 1;
        final dayDate = DateTime(monthDate.year, monthDate.month, dayNum);
        final isSelected = dayDate.year == _selectedDate.year &&
            dayDate.month == _selectedDate.month &&
            dayDate.day == _selectedDate.day;

        final dateKey =
            '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
        final hasMatch = _normalizedMatchDates.contains(dateKey);
        final hasUpcomingMatch =
            _normalizedUpcomingMatchDates.contains(dateKey);

        final now = DateTime.now();
        final isToday = dayDate.year == now.year &&
            dayDate.month == now.month &&
            dayDate.day == now.day;

        final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final firstStart = DateTime(widget.firstDate.year,
            widget.firstDate.month, widget.firstDate.day);
        final lastStart = DateTime(
            widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

        final isDisabled =
            dayStart.isBefore(firstStart) || dayStart.isAfter(lastStart);

        return InkWell(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedDate = dayDate;
                  });
                },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      color: isDisabled
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87),
                      fontWeight: isSelected || isToday || hasMatch
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (hasMatch)
                Builder(
                  builder: (context) {
                    final badgeColor = hasUpcomingMatch
                        ? const Color(0xFF2196F3)
                        : AppColors.primary;

                    return Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color:
                              badgeColor, // Blue for upcoming matches ahead, Green for past matches
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (hasUpcomingMatch
                                    ? AppColors.primary
                                    : Colors.white)
                                : (isDark ? AppColors.darkCard : Colors.white),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearMonthPicker(bool isDark) {
    final currentYear = _displayedMonth.year;
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelectedYear = year == currentYear;
          return InkWell(
            onTap: () {
              final targetMonth = DateTime(year, _displayedMonth.month, 1);
              int targetPage = (targetMonth.year - _startMonth.year) * 12 +
                  (targetMonth.month - _startMonth.month);
              targetPage = targetPage.clamp(0, _totalMonths - 1);

              if (_pageController.hasClients) {
                _pageController.jumpToPage(targetPage);
              }
              setState(() {
                _displayedMonth = targetMonth;
                _isYearPicker = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        isSelectedYear ? FontWeight.bold : FontWeight.normal,
                    color: isSelectedYear
                        ? AppColors.primary
                        : (isDark ? AppColors.textPrimaryDark : Colors.black87),
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
