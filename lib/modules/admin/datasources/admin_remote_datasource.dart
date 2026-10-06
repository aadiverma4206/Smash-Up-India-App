import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/admin_models.dart';

class AdminRemoteDataSource {
  final DioClient dioClient;

  AdminRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<AdminDashboardModel>> getDashboard() async {
    final response = await dioClient.dio.get('/admin/dashboard');
    return ApiResponseParser.parse<AdminDashboardModel>(
      response.data,
      (json) => AdminDashboardModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<List<AdminUserModel>>> getUsers(
      {String? search, int page = 1}) async {
    final response = await dioClient.dio.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      },
    );
    return ApiResponseParser.parse<List<AdminUserModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> suspendUser(
      String userId, String reason) async {
    final response = await dioClient.dio.post(
      '/admin/users/$userId/suspend',
      data: {'reason': reason},
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> unsuspendUser(
      String userId) async {
    final response = await dioClient.dio.post('/admin/users/$userId/unsuspend');
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> createManager({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String city,
  }) async {
    final response = await dioClient.dio.post(
      '/admin/managers',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'city': city,
      },
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }
}
