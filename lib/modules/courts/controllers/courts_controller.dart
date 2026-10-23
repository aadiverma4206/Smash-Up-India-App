import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
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
  final RxString selectedStatusFilter = 'ALL'.obs; // ALL, AVAILABLE, MAINTENANCE, BLOCKED
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourts();
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
