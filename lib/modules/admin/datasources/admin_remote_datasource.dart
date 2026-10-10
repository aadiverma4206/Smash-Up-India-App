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
      {String? search, int? roleId, int limit = 50, int page = 1}) async {
    final response = await dioClient.dio.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (roleId != null) 'role_id': roleId,
        'limit': limit,
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
    final response = await dioClient.dio.patch(
      '/admin/users/$userId/suspend',
      data: {
        'suspend': true,
        'reason': reason,
      },
    );
    return ApiResponseParser.parse<Map<String, dynamic>>(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponseModel<Map<String, dynamic>>> unsuspendUser(
      String userId) async {
    final response = await dioClient.dio.patch(
      '/admin/users/$userId/suspend',
      data: {
        'suspend': false,
      },
    );
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

  Future<ApiResponseModel<List<AuditLogModel>>> getAuditLogs(
      {int page = 1, int limit = 40}) async {
    final response = await dioClient.dio.get(
      '/admin/audit-logs',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return ApiResponseParser.parse<List<AuditLogModel>>(
      response.data,
      (json) => (json as List)
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
