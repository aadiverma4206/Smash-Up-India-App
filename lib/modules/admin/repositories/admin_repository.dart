import '../datasources/admin_remote_datasource.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/errors/app_exception.dart';

class AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepository({required this.remoteDataSource});

  Future<AdminDashboardModel> getDashboard() async {
    final response = await remoteDataSource.getDashboard();
    if (response.data == null) {
      throw AppException('Admin dashboard data could not be retrieved.');
    }
    return response.data!;
  }

  Future<List<AdminUserModel>> getUsers({String? search, int page = 1}) async {
    final response =
        await remoteDataSource.getUsers(search: search, page: page);
    return response.data ?? [];
  }

  Future<void> suspendUser(String userId, String reason) async {
    await remoteDataSource.suspendUser(userId, reason);
  }

  Future<void> unsuspendUser(String userId) async {
    await remoteDataSource.unsuspendUser(userId);
  }

  Future<void> createManager({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String city,
  }) async {
    await remoteDataSource.createManager(
      name: name,
      email: email,
      phone: phone,
      password: password,
      city: city,
    );
  }
}
