import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';

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
  final RxList<Map<String, dynamic>> scheduledGames =
      <Map<String, dynamic>>[].obs;
  final RxBool isScheduleLoading = false.obs;

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
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final response =
          await dioClient.dio.get('/games', queryParameters: {'date': dateStr});
      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is List) {
        scheduledGames.assignAll(
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        scheduledGames.clear();
      }
    } catch (_) {
      try {
        final response = await dioClient.dio.get(
            '/manager/courts/${chartCourtId.value}/slots',
            queryParameters: {'date': dateStr});
        final raw = response.data is Map
            ? response.data['data'] ?? response.data['slots']
            : response.data;
        if (raw is List) {
          scheduledGames.assignAll(
              raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        } else {
          scheduledGames.clear();
        }
      } catch (e) {
        AppLogger.warning('Schedule fetch warning: $e');
        scheduledGames.clear();
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

  Map<String, dynamic>? getBookingForHour(int hour, String courtId) {
    final targetCourt = courtId.toLowerCase();
    for (final game in scheduledGames) {
      final gCourt =
          (game['courtId'] ?? game['court_id'] ?? '').toString().toLowerCase();

      if (gCourt.isNotEmpty) {
        if (targetCourt == 'court_1' && gCourt.contains('2')) continue;
        if (targetCourt == 'court_2' && gCourt.contains('1')) continue;
      }

      final status = (game['status'] ?? '').toString().toUpperCase();
      final approval = (game['approvalStatus'] ?? game['approval_status'] ?? '')
          .toString()
          .toUpperCase();
      if (status == 'CANCELLED' || approval == 'REJECTED') continue;

      final startTimeStr =
          (game['startTime'] ?? game['start_time'] ?? '').toString();
      if (startTimeStr.isNotEmpty) {
        final parts = startTimeStr.split(':');
        if (parts.isNotEmpty) {
          final startHour = int.tryParse(parts[0]);
          if (startHour != null && startHour == hour) {
            return game;
          }
        }
      }
    }
    return null;
  }

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
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Booking Failed', e);
    } finally {
      isLoading.value = false;
    }
  }
}
