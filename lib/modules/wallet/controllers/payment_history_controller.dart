import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../repositories/wallet_repository.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_logger.dart';

class DateGroupedTransactions {
  final String dateHeader;
  final List<WalletTransactionModel> items;

  DateGroupedTransactions({required this.dateHeader, required this.items});
}

class PlayerPaymentHistoryController extends GetxController {
  late final WalletRepository repository;

  final RxList<WalletTransactionModel> allTransactions =
      <WalletTransactionModel>[].obs;
  final RxList<WalletTransactionModel> filteredTransactions =
      <WalletTransactionModel>[].obs;
  final RxList<DateGroupedTransactions> groupedTransactions =
      <DateGroupedTransactions>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'ALL'.obs;

  final List<String> typeFilters = [
    'ALL',
    'TOPUP',
    'PITCH BOOKING',
    'DEBIT',
    'REFUND'
  ];

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<WalletRemoteDataSource>()) {
      Get.lazyPut<WalletRemoteDataSource>(
        () => WalletRemoteDataSource(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<WalletRepository>()) {
      Get.lazyPut<WalletRepository>(
        () => WalletRepository(
            remoteDataSource: Get.find<WalletRemoteDataSource>()),
        fenix: true,
      );
    }
    repository = Get.find<WalletRepository>();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final cachedList = await repository.getLocalCachedTransactions();
    if (cachedList.isNotEmpty) {
      allTransactions.value = cachedList;
      applyFilters();
    } else {
      isLoading.value = true;
    }

    errorMessage.value = '';
    try {
      final list = await repository.getTransactions(page: 1, limit: 100);
      if (list.isNotEmpty) {
        allTransactions.value = list;
        applyFilters();
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch ledger transactions: $e');
      if (allTransactions.isEmpty) {
        errorMessage.value = 'Failed to load transaction history.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  void applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = selectedFilter.value.toUpperCase();

    final result = allTransactions.where((tx) {
      final txType = tx.transactionType.toUpperCase();
      final descLower = tx.description.toLowerCase();

      final isRefund = txType == 'REFUND' ||
          txType == 'CANCEL_REFUND' ||
          txType == 'MATCH_REFUND' ||
          txType == 'REFUNDED' ||
          descLower.contains('refund') ||
          descLower.contains('cancel');

      final isTopup = txType == 'TOPUP' ||
          txType == 'CREDIT' ||
          txType == 'DEPOSIT' ||
          txType == 'WALLET_TOPUP' ||
          descLower.contains('topup') ||
          descLower.contains('top-up') ||
          descLower.contains('add money');

      final isPitchBooking = txType == 'RAZORPAY_BOOKING' ||
          txType == 'DIRECT_BOOKING' ||
          txType == 'PITCH_BOOKING' ||
          txType == 'MATCH_JOIN' ||
          descLower.contains('pitch') ||
          descLower.contains('turf') ||
          descLower.contains('match') ||
          descLower.contains('slot');

      final isDebit = txType == 'DEBIT' ||
          txType == 'PAYMENT' ||
          txType == 'WITHDRAWAL' ||
          isPitchBooking;

      bool matchesFilter = (filter == 'ALL');
      if (filter == 'REFUND') matchesFilter = isRefund;
      if (filter == 'TOPUP') matchesFilter = isTopup;
      if (filter == 'PITCH BOOKING') matchesFilter = isPitchBooking;
      if (filter == 'DEBIT') matchesFilter = isDebit;

      final matchesQuery = query.isEmpty ||
          descLower.contains(query) ||
          txType.toLowerCase().contains(query) ||
          tx.status.toLowerCase().contains(query) ||
          tx.amount.toString().contains(query);

      return matchesFilter && matchesQuery;
    }).toList();

    filteredTransactions.value = result;
    groupedTransactions.value = _groupTxsByDate(result);
  }

  List<DateGroupedTransactions> _groupTxsByDate(
      List<WalletTransactionModel> txs) {
    final Map<String, List<WalletTransactionModel>> groupMap = {};

    for (final tx in txs) {
      String headerKey = 'Recent Transactions';
      try {
        final parsedDate =
            DateTime.tryParse(tx.createdAt)?.toLocal() ?? DateTime.now();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final txDate =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        if (txDate == today) {
          headerKey = 'Today, ${DateFormat('dd MMM yyyy').format(parsedDate)}';
        } else if (txDate == today.subtract(const Duration(days: 1))) {
          headerKey =
              'Yesterday, ${DateFormat('dd MMM yyyy').format(parsedDate)}';
        } else {
          headerKey = DateFormat('EEE, dd MMM yyyy').format(parsedDate);
        }
      } catch (_) {}

      groupMap.putIfAbsent(headerKey, () => []).add(tx);
    }

    return groupMap.entries
        .map((entry) => DateGroupedTransactions(
              dateHeader: entry.key,
              items: entry.value,
            ))
        .toList();
  }
}
