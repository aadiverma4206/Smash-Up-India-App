import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/app_logger.dart';

class SlotAvailabilityItem {
  final int hour;
  final String startTime;
  final String endTime;
  final String status; // "AVAILABLE", "BOOKED", "PENDING", "UNAVAILABLE"
  final String? title;
  final String? source;
  final double price;
  final String? exactStartTime;
  final String? exactEndTime;
  final int? exactDurationMinutes;

  SlotAvailabilityItem({
    required this.hour,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.title,
    this.source,
    required this.price,
    this.exactStartTime,
    this.exactEndTime,
    this.exactDurationMinutes,
  });

  bool get isAvailable => status == 'AVAILABLE';
  bool get isBooked => status == 'BOOKED';
  bool get isPending => status == 'PENDING';
  bool get isUnavailable => status == 'UNAVAILABLE';

  String get formattedExactTimeRange {
    final startToUse = exactStartTime ?? startTime;
    final endToUse = exactEndTime ?? endTime;
    final formattedStart = AppDateUtils.formatTime(startToUse);
    final formattedEnd = AppDateUtils.formatTime(endToUse);

    if (exactDurationMinutes != null && exactDurationMinutes! > 0) {
      if (exactDurationMinutes! % 60 == 0) {
        final hrs = exactDurationMinutes! ~/ 60;
        return '$formattedStart - $formattedEnd ($hrs ${hrs == 1 ? "hr" : "hrs"})';
      }
      return '$formattedStart - $formattedEnd ($exactDurationMinutes mins)';
    }
    return '$formattedStart - $formattedEnd';
  }

  String get formattedDurationText {
    if (exactDurationMinutes != null && exactDurationMinutes! > 0) {
      if (exactDurationMinutes! % 60 == 0) {
        final hrs = exactDurationMinutes! ~/ 60;
        return '$hrs ${hrs == 1 ? "hr" : "hrs"} (${exactDurationMinutes!}m)';
      }
      return '${exactDurationMinutes!} mins';
    }
    return '1 hr (60m)';
  }
}

class CourtsController extends GetxController {
  final DioClient dioClient = Get.find<DioClient>();

  final RxList<CourtModel> courts = <CourtModel>[].obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;

  // Filter state
  final RxString selectedStatusFilter =
      'ALL'.obs; // ALL, AVAILABLE, MAINTENANCE, BLOCKED
  final RxString searchQuery = ''.obs;

  // Chart & Hourly Availability State
  final Rx<DateTime> chartSelectedDate = DateTime.now().obs;
  final RxString chartDateFilter = 'TODAY'.obs; // 'TODAY', 'TOMORROW', 'CUSTOM'
  final RxString chartCourtId = 'court_1'.obs; // 'court_1', 'court_2'
  final RxList<Map<String, dynamic>> availabilityData =
      <Map<String, dynamic>>[].obs;
  final RxBool isScheduleLoading = false.obs;
  final RxString scheduleErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourts();
    fetchScheduleForDate(DateTime.now());
  }

  Future<void> fetchCourts() async {
    isLoading.value = true;
    try {
      final response = await dioClient.dio.get('/courts');
      final rawData = response.data is Map<String, dynamic>
          ? response.data['data']
          : response.data;
      if (rawData is List) {
        final list = rawData
            .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
            .toList();
        courts.assignAll(list);
      }
    } catch (e) {
      AppLogger.warning('Error fetching courts: $e');
      if (courts.isEmpty) {
        courts.assignAll([
          CourtModel(
            id: 'court_1',
            clubId: 'all_stars_arena_club',
            clubName: 'All Stars Turf Raipur',
            name: 'Court 1',
            surfaceType: '3G Turf',
            basePricePerHour: 1200.0,
            status: 'AVAILABLE',
            city: 'Raipur',
            address: 'VIP Road, Raipur',
          ),
          CourtModel(
            id: 'court_2',
            clubId: 'all_stars_arena_club',
            clubName: 'All Stars Turf Raipur',
            name: 'Court 2',
            surfaceType: '3G Turf',
            basePricePerHour: 1200.0,
            status: 'AVAILABLE',
            city: 'Raipur',
            address: 'VIP Road, Raipur',
          ),
        ]);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchScheduleForDate(DateTime date) async {
    isScheduleLoading.value = true;
    scheduleErrorMessage.value = '';
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final activeCourt = chartCourtId.value;

    try {
      final response = await dioClient.dio.get(
        '/courts/$activeCourt/availability',
        queryParameters: {'date': dateStr},
      );
      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is List) {
        availabilityData.assignAll(
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        availabilityData.clear();
      }
    } catch (e) {
      AppLogger.warning('Error fetching court availability: $e');
      try {
        final response = await dioClient.dio.get(
          '/games',
          queryParameters: {'date': dateStr, 'courtId': activeCourt},
        );
        final raw = response.data is Map ? response.data['data'] : response.data;
        if (raw is List) {
          availabilityData.assignAll(
              raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        } else {
          availabilityData.clear();
        }
      } catch (_) {
        availabilityData.clear();
      }
    } finally {
      isScheduleLoading.value = false;
    }
  }

  void setChartDateFilter(String filter, BuildContext context) async {
    chartDateFilter.value = filter;
    final now = DateTime.now();
    if (filter == 'TODAY') {
      chartSelectedDate.value = DateTime(now.year, now.month, now.day);
    } else if (filter == 'TOMORROW') {
      chartSelectedDate.value =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    } else if (filter == 'CUSTOM') {
      final picked = await showDatePicker(
        context: context,
        initialDate: chartSelectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        chartSelectedDate.value = picked;
      }
    }
    fetchScheduleForDate(chartSelectedDate.value);
  }

  void setChartCourt(String courtId) {
    chartCourtId.value = courtId;
    fetchScheduleForDate(chartSelectedDate.value);
  }

  List<SlotAvailabilityItem> getSlotsForActiveCourt() {
    final activeCourtId = chartCourtId.value;
    final CourtModel? courtModel = courts.firstWhereOrNull(
      (c) => c.id.toLowerCase() == activeCourtId.toLowerCase(),
    );

    final courtStatus = courtModel?.status.toUpperCase() ?? 'AVAILABLE';
    final hourlyRate = courtModel?.basePricePerHour ?? 1200.0;

    final List<SlotAvailabilityItem> items = [];
    final hours = List.generate(18, (i) => i + 6); // 6 AM to 11 PM (18 hours)

    for (final hour in hours) {
      final startStr = '${hour.toString().padLeft(2, '0')}:00';
      final endHour = (hour + 1) % 24;
      final endStr = '${endHour.toString().padLeft(2, '0')}:00';

      if (courtStatus == 'MAINTENANCE' || courtStatus == 'BLOCKED') {
        items.add(SlotAvailabilityItem(
          hour: hour,
          startTime: startStr,
          endTime: endStr,
          status: 'UNAVAILABLE',
          title: courtStatus == 'MAINTENANCE'
              ? 'Court Maintenance'
              : 'Court Blocked',
          price: hourlyRate,
        ));
        continue;
      }

      Map<String, dynamic>? matchFound;
      for (final slot in availabilityData) {
        final sCourt = (slot['courtId'] ?? slot['court_id'] ?? '')
            .toString()
            .toLowerCase();
        if (sCourt.isNotEmpty) {
          if (activeCourtId == 'court_1' && sCourt.contains('2')) continue;
          if (activeCourtId == 'court_2' && sCourt.contains('1')) continue;
        }

        final status = (slot['status'] ?? '').toString().toUpperCase();
        final approval =
            (slot['approvalStatus'] ?? slot['approval_status'] ?? '')
                .toString()
                .toUpperCase();
        if (status == 'CANCELLED' || approval == 'REJECTED') continue;

        final rawStart =
            (slot['startTime'] ?? slot['start_time'] ?? '').toString();
        final rawEnd = (slot['endTime'] ?? slot['end_time'] ?? '').toString();

        if (rawStart.isNotEmpty) {
          final sParts = rawStart.split(':');
          final sH = int.tryParse(sParts[0]) ?? 0;

          var eH = sH + 1;
          if (rawEnd.isNotEmpty) {
            final eParts = rawEnd.split(':');
            final parsedEH = int.tryParse(eParts[0]);
            final parsedEMin =
                eParts.length > 1 ? (int.tryParse(eParts[1]) ?? 0) : 0;
            if (parsedEH != null) {
              eH = parsedEMin > 0 ? parsedEH + 1 : parsedEH;
            }
          }

          if (hour >= sH && hour < eH) {
            matchFound = slot;
            break;
          }
        }
      }

      if (matchFound != null) {
        final st = (matchFound['status'] ?? '').toString().toUpperCase();
        final title = (matchFound['title'] ?? 'Booked').toString();
        final isPending = st == 'PENDING';

        final rawStart =
            (matchFound['startTime'] ?? matchFound['start_time'] ?? '')
                .toString();
        final rawEnd =
            (matchFound['endTime'] ?? matchFound['end_time'] ?? '').toString();

        int? durationMins;
        if (rawStart.isNotEmpty && rawEnd.isNotEmpty) {
          try {
            final sParts = rawStart.split(':');
            final eParts = rawEnd.split(':');
            final sH = int.parse(sParts[0]);
            final sM = sParts.length > 1 ? int.parse(sParts[1]) : 0;
            final eH = int.parse(eParts[0]);
            final eM = eParts.length > 1 ? int.parse(eParts[1]) : 0;

            final startTotalMins = sH * 60 + sM;
            var endTotalMins = eH * 60 + eM;
            if (endTotalMins <= startTotalMins) {
              endTotalMins += 24 * 60;
            }
            durationMins = endTotalMins - startTotalMins;
          } catch (_) {}
        }

        items.add(SlotAvailabilityItem(
          hour: hour,
          startTime: startStr,
          endTime: endStr,
          status: isPending ? 'PENDING' : 'BOOKED',
          title: title,
          source: matchFound['source']?.toString(),
          price: hourlyRate,
          exactStartTime: rawStart.isNotEmpty ? rawStart : startStr,
          exactEndTime: rawEnd.isNotEmpty ? rawEnd : endStr,
          exactDurationMinutes: durationMins,
        ));
      } else {
        items.add(SlotAvailabilityItem(
          hour: hour,
          startTime: startStr,
          endTime: endStr,
          status: 'AVAILABLE',
          price: hourlyRate,
        ));
      }
    }

    return items;
  }

  int get activeCourtAvailableSlotsCount =>
      getSlotsForActiveCourt().where((s) => s.isAvailable).length;

  int get activeCourtBookedSlotsCount =>
      getSlotsForActiveCourt().where((s) => s.isBooked || s.isPending).length;

  int get activeCourtUnavailableSlotsCount =>
      getSlotsForActiveCourt().where((s) => s.isUnavailable).length;

  void setStatusFilter(String status) {
    selectedStatusFilter.value = status;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<CourtModel> get filteredCourts {
    return courts.where((court) {
      final statusMatch = selectedStatusFilter.value == 'ALL' ||
          court.status.toUpperCase() == selectedStatusFilter.value;

      final query = searchQuery.value.trim().toLowerCase();
      final searchMatch = query.isEmpty ||
          court.name.toLowerCase().contains(query) ||
          court.surfaceType.toLowerCase().contains(query) ||
          court.clubName.toLowerCase().contains(query) ||
          court.city.toLowerCase().contains(query);

      return statusMatch && searchMatch;
    }).toList();
  }

  int get totalCount => courts.length;
  int get availableCount =>
      courts.where((c) => c.status.toUpperCase() == 'AVAILABLE').length;
  int get maintenanceCount =>
      courts.where((c) => c.status.toUpperCase() == 'MAINTENANCE').length;
  int get blockedCount =>
      courts.where((c) => c.status.toUpperCase() == 'BLOCKED').length;

  Future<void> bookCourt(
      String courtId, String date, String startTime, String endTime) async {
    final court = courts.firstWhereOrNull(
      (c) => c.id.toLowerCase() == courtId.toLowerCase(),
    );
    final status = (court?.status ?? '').toUpperCase();
    if (status == 'MAINTENANCE' || status == 'BLOCKED') {
      ErrorHandler.showWarningSnackBar(
        'Court Unavailable',
        '${court?.name ?? "Selected court"} is currently in $status status and cannot be booked.',
      );
      return;
    }

    isLoading.value = true;
    try {
      await dioClient.dio.post(
        '/bookings',
        data: {
          'courtId': courtId,
          'bookingDate': date,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      ErrorHandler.showSuccessSnackBar(
          'Booking Confirmed', 'Turf pitch booked successfully!');
      fetchScheduleForDate(chartSelectedDate.value);
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Booking Failed', e);
    } finally {
      isLoading.value = false;
    }
  }
}
