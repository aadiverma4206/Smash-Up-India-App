import 'dart:async';
import 'package:get/get.dart';
import '../repositories/admin_repository.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/connectivity_service.dart';

class AdminController extends GetxController {
  final AdminRepository repository = Get.find<AdminRepository>();

  final Rxn<AdminDashboardModel> dashboard = Rxn<AdminDashboardModel>();
  final RxList<AdminUserModel> users = <AdminUserModel>[].obs;
  final RxList<AdminUserModel> players = <AdminUserModel>[].obs;
  final RxList<AdminUserModel> managers = <AdminUserModel>[].obs;

  final RxList<AuditLogModel> auditLogs = <AuditLogModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPlayers = false.obs;
  final RxBool isLoadingManagers = false.obs;
  final RxBool isLoadingLogs = false.obs;

  int playerPage = 1;
  final RxBool hasMorePlayers = true.obs;
  final RxBool isLoadingMorePlayers = false.obs;

  int managerPage = 1;
  final RxBool hasMoreManagers = true.obs;
  final RxBool isLoadingMoreManagers = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString playerSearchQuery = ''.obs;
  final RxString managerSearchQuery = ''.obs;

  final RxInt selectedNavIndex = 0.obs;

  final RxList<AdminPaymentModel> payments = <AdminPaymentModel>[].obs;
  final Rxn<AdminPaymentSummaryModel> paymentSummary =
      Rxn<AdminPaymentSummaryModel>();
  final RxBool isLoadingPayments = false.obs;
  final RxString paymentSearchQuery = ''.obs;
  final RxString selectedPaymentFilter = 'ALL'.obs;

  Timer? _playerSearchTimer;
  Timer? _managerSearchTimer;
  Timer? _paymentSearchTimer;

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    fetchUsers();
    fetchPlayers();
    fetchManagers();
    fetchPaymentHistory();

    if (Get.isRegistered<ConnectivityService>()) {
      ConnectivityService.to.isConnected.listen((connected) {
        if (connected) {
          AppLogger.info(
              '⚡ Connection restored: Auto-refreshing admin dashboard & users');
          loadDashboard();
          fetchUsers();
          fetchPlayers();
          fetchManagers();
        }
      });
    }
  }

  @override
  void onClose() {
    _playerSearchTimer?.cancel();
    _managerSearchTimer?.cancel();
    _paymentSearchTimer?.cancel();
    super.onClose();
  }

  void onPlayerSearchChanged(String query) {
    playerSearchQuery.value = query;
    _playerSearchTimer?.cancel();
    _playerSearchTimer = Timer(const Duration(milliseconds: 250), () {
      fetchPlayers();
    });
  }

  void onManagerSearchChanged(String query) {
    managerSearchQuery.value = query;
    _managerSearchTimer?.cancel();
    _managerSearchTimer = Timer(const Duration(milliseconds: 250), () {
      fetchManagers();
    });
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final d = await repository.getDashboard();
      dashboard.value = d;
    } catch (e) {
      AppLogger.warning('Admin dashboard load error: $e');
      if (dashboard.value == null) {
        ErrorHandler.showErrorSnackBar('Dashboard Error', e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUsers() async {
    try {
      final list = await repository.getUsers(
        search: searchQuery.value,
        limit: 50,
      );
      users.assignAll(list);
    } catch (e) {
      AppLogger.warning('Failed to fetch users: $e');
    }
  }

  Future<void> fetchPlayers({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!hasMorePlayers.value || isLoadingMorePlayers.value) return;
      isLoadingMorePlayers.value = true;
    } else {
      playerPage = 1;
      hasMorePlayers.value = true;
      if (players.isEmpty) {
        isLoadingPlayers.value = true;
      }
    }

    final targetPage = isLoadMore ? playerPage + 1 : 1;

    try {
      final list = await repository.getUsers(
        search: playerSearchQuery.value,
        roleId: 3,
        limit: 50,
        page: targetPage,
        onCachedData: (!isLoadMore)
            ? (cachedList) {
                players.assignAll(cachedList);
                isLoadingPlayers.value = false;
              }
            : null,
      );

      if (isLoadMore) {
        final existingIds = players.map((e) => e.id).toSet();
        final newEntries =
            list.where((e) => !existingIds.contains(e.id)).toList();
        players.addAll(newEntries);

        players.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        playerPage = targetPage;
      } else {
        players.assignAll(list);
        playerPage = 1;
      }

      hasMorePlayers.value = (list.length >= 50);
    } catch (e) {
      AppLogger.warning('Failed to fetch players: $e');
    } finally {
      isLoadingPlayers.value = false;
      isLoadingMorePlayers.value = false;
    }
  }

  Future<void> fetchManagers({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!hasMoreManagers.value || isLoadingMoreManagers.value) return;
      isLoadingMoreManagers.value = true;
    } else {
      managerPage = 1;
      hasMoreManagers.value = true;
      if (managers.isEmpty) {
        isLoadingManagers.value = true;
      }
    }

    final targetPage = isLoadMore ? managerPage + 1 : 1;

    try {
      final list = await repository.getUsers(
        search: managerSearchQuery.value,
        roleId: 2,
        limit: 50,
        page: targetPage,
        onCachedData: (!isLoadMore)
            ? (cachedList) {
                managers.assignAll(cachedList);
                isLoadingManagers.value = false;
              }
            : null,
      );

      if (isLoadMore) {
        final existingIds = managers.map((e) => e.id).toSet();
        final newEntries =
            list.where((e) => !existingIds.contains(e.id)).toList();
        managers.addAll(newEntries);

        managers.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        managerPage = targetPage;
      } else {
        managers.assignAll(list);
        managerPage = 1;
      }

      hasMoreManagers.value = (list.length >= 50);
    } catch (e) {
      AppLogger.warning('Failed to fetch managers: $e');
    } finally {
      isLoadingManagers.value = false;
      isLoadingMoreManagers.value = false;
    }
  }

  int auditLogPage = 1;
  final RxBool hasMoreAuditLogs = true.obs;
  final RxBool isLoadingMoreAuditLogs = false.obs;

  Future<void> fetchAuditLogs({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!hasMoreAuditLogs.value || isLoadingMoreAuditLogs.value) return;
      isLoadingMoreAuditLogs.value = true;
    } else {
      auditLogPage = 1;
      hasMoreAuditLogs.value = true;
      if (auditLogs.isEmpty) {
        isLoadingLogs.value = true;
      }
    }

    final targetPage = isLoadMore ? auditLogPage + 1 : 1;

    try {
      final logs = await repository.getAuditLogs(page: targetPage, limit: 40);

      if (isLoadMore) {
        final existingIds = auditLogs.map((e) => e.id).toSet();
        final newEntries =
            logs.where((e) => !existingIds.contains(e.id)).toList();
        auditLogs.addAll(newEntries);
        auditLogPage = targetPage;
      } else {
        auditLogs.assignAll(logs);
        auditLogPage = 1;
      }

      hasMoreAuditLogs.value = (logs.length >= 40);
    } catch (e) {
      AppLogger.warning('Failed to fetch audit logs: $e');
    } finally {
      isLoadingLogs.value = false;
      isLoadingMoreAuditLogs.value = false;
    }
  }

  Future<void> suspendUser(String userId) async {
    isLoading.value = true;
    try {
      await repository.suspendUser(userId, 'Administrative Suspension');
      await refreshAllUsers();
      ErrorHandler.showSuccessSnackBar(
          'Account Suspended', 'User account was suspended.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unsuspendUser(String userId) async {
    isLoading.value = true;
    try {
      await repository.unsuspendUser(userId);
      await refreshAllUsers();
      ErrorHandler.showSuccessSnackBar(
          'Account Reactivated', 'User account is now ACTIVE.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAllUsers() async {
    await Future.wait([
      fetchUsers(),
      fetchPlayers(),
      fetchManagers(),
      loadDashboard(),
    ]);
  }

  Future<void> createManager({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String city,
  }) async {
    isLoading.value = true;
    try {
      await repository.createManager(
        name: name,
        email: email,
        phone: phone,
        password: password,
        city: city,
      );
      Get.back();
      await refreshAllUsers();
      ErrorHandler.showSuccessSnackBar(
          'Manager Created', 'Turf Manager account created successfully.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Creation Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  void onPaymentSearchChanged(String query) {
    paymentSearchQuery.value = query;
    _paymentSearchTimer?.cancel();
    _paymentSearchTimer = Timer(const Duration(milliseconds: 250), () {
      fetchPaymentHistory();
    });
  }

  void setPaymentFilter(String status) {
    selectedPaymentFilter.value = status;
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
    isLoadingPayments.value = true;
    try {
      final res = await repository.getPayments(
        search: paymentSearchQuery.value,
        status: selectedPaymentFilter.value == 'ALL'
            ? null
            : selectedPaymentFilter.value,
        limit: 50,
      );

      if (res['summary'] != null) {
        paymentSummary.value = AdminPaymentSummaryModel.fromJson(
            res['summary'] as Map<String, dynamic>);
      }

      if (res['payments'] != null && res['payments'] is List) {
        final list = (res['payments'] as List)
            .map((e) => AdminPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        payments.assignAll(list);
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch payment history: $e');
    } finally {
      isLoadingPayments.value = false;
    }
  }

  Future<void> processRefund(String paymentId, String reason) async {
    isLoading.value = true;
    try {
      await repository.processRefund(paymentId: paymentId, reason: reason);
      await fetchPaymentHistory();
      await loadDashboard();
      ErrorHandler.showSuccessSnackBar(
          'Refund Issued', 'Payment refund processed successfully.');
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Refund Error', e);
    } finally {
      isLoading.value = false;
    }
  }
}
