import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../data/models/court_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../core/errors/error_handler.dart';

class CourtsController extends GetxController {
  final DioClient dioClient = Get.find<DioClient>();

  final RxList<CourtModel> courts = <CourtModel>[].obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourts();
  }

  Future<void> fetchCourts() async {
    isLoading.value = true;
    try {
      final response = await dioClient.dio.get('/courts');
      final parsed = ApiResponseParser.parse<List<CourtModel>>(
        response.data,
        (json) => (json as List)
            .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      courts.assignAll(parsed.data ?? []);
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

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
