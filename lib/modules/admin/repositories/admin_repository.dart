import 'dart:convert';
import 'package:get/get.dart';
import '../datasources/admin_remote_datasource.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/utils/app_logger.dart';

class AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepository({required this.remoteDataSource});

  DatabaseService get _dbService => Get.find<DatabaseService>();

  Future<AdminDashboardModel> getDashboard() async {
    final response = await remoteDataSource.getDashboard();
    if (response.data == null) {
      throw AppException('Admin dashboard data could not be retrieved.');
    }
    return response.data!;
  }

  Future<List<AdminUserModel>> getUsers({
    String? search,
    int? roleId,
    int limit = 50,
    int page = 1,
    Function(List<AdminUserModel> cachedList)? onCachedData,
  }) async {
    final cleanSearch = search?.trim().toLowerCase() ?? '';
    final cacheKey =
        'admin_users_role_${roleId ?? 0}_q_${cleanSearch}_p_${page}_l_$limit';

    try {
      await _dbService.pruneExpiredCache(maxAge: const Duration(days: 5));
    } catch (_) {}

    if (page == 1) {
      try {
        final cachedJsonStr = await _dbService.getValidCachedData(
          cacheKey,
          maxAge: const Duration(days: 5),
        );
        if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedJsonStr);
          final cachedList = _processUserList(
            decoded
                .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
                .toList(),
            limit: limit,
          );
          if (onCachedData != null && cachedList.isNotEmpty) {
            onCachedData(cachedList);
          }
        }
      } catch (e) {
        AppLogger.warning('SQLite cache read warning: $e');
      }
    }

    try {
      final response = await remoteDataSource.getUsers(
        search: cleanSearch,
        roleId: roleId,
        limit: limit,
        page: page,
      );

      final rawList = response.data ?? [];
      final processedList = _processUserList(rawList, limit: limit);

      if (page == 1) {
        try {
          final jsonToStore =
              jsonEncode(processedList.map((e) => e.toJson()).toList());
          await _dbService.cacheData(cacheKey, jsonToStore);
        } catch (e) {
          AppLogger.warning('SQLite cache write warning: $e');
        }
      }

      return processedList;
    } catch (e) {
      if (page == 1) {
        try {
          final fallbackJson = await _dbService.getCachedData(cacheKey);
          if (fallbackJson != null) {
            final List<dynamic> decoded = jsonDecode(fallbackJson);
            return _processUserList(
              decoded
                  .map(
                      (e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
                  .toList(),
              limit: limit,
            );
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  List<AdminUserModel> _processUserList(List<AdminUserModel> list,
      {int limit = 50}) {
    final seenIds = <String>{};
    final uniqueList = <AdminUserModel>[];

    for (final user in list) {
      if (!seenIds.contains(user.id)) {
        seenIds.add(user.id);
        uniqueList.add(user);
      }
    }

    uniqueList
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (uniqueList.length > limit) {
      return uniqueList.sublist(0, limit);
    }
    return uniqueList;
  }

  Future<void> clearUserCache() async {
    try {
      await _dbService.clearCache();
    } catch (_) {}
  }

  Future<void> suspendUser(String userId, String reason) async {
    await remoteDataSource.suspendUser(userId, reason);
    await clearUserCache();
  }

  Future<void> unsuspendUser(String userId) async {
    await remoteDataSource.unsuspendUser(userId);
    await clearUserCache();
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
    await clearUserCache();
  }

  Future<List<AuditLogModel>> getAuditLogs(
      {int page = 1, int limit = 40}) async {
    final response =
        await remoteDataSource.getAuditLogs(page: page, limit: limit);
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> getPayments({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await remoteDataSource.getPayments(
      search: search,
      status: status,
      page: page,
      limit: limit,
    );
    return response.data ?? {};
  }

  Future<void> processRefund({
    required String paymentId,
    required String reason,
  }) async {
    await remoteDataSource.processRefund(
      paymentId: paymentId,
      reason: reason,
    );
  }
}
