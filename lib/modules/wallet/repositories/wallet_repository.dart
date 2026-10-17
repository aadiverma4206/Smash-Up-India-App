import 'dart:convert';
import 'package:get/get.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/utils/app_logger.dart';

class WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepository({required this.remoteDataSource});

  static const String _cacheKey = 'wallet_transactions_cache';

  Future<WalletBalanceModel> getWallet() async {
    // Admin (Role 1) and Manager (Role 2) do not have player wallets.
    // Return zero-balance stub locally without making network request to /api/v1/wallet.
    if (Get.isRegistered<AuthService>() && !AuthService.to.isPlayer) {
      return WalletBalanceModel(balance: 0, hasPin: false);
    }

    final response = await remoteDataSource.getWallet();
    if (response.data == null) {
      throw AppException('Wallet details not found.');
    }
    return response.data!;
  }

  Future<RazorpayOrderModel> createTopupOrder(
      double amountRupees, String idempotencyKey,
      {String? walletPin}) async {
    final response = await remoteDataSource
        .createTopupOrder(amountRupees, idempotencyKey, walletPin: walletPin);
    if (response.data == null) {
      throw AppException('Failed to create payment order.');
    }
    return response.data!;
  }

  Future<WalletBalanceModel> verifyTopupPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? paymentOrderId,
  }) async {
    final response = await remoteDataSource.verifyTopupPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      paymentOrderId: paymentOrderId,
    );
    if (response.data == null) {
      throw AppException('Payment verification failed.');
    }
    return response.data!;
  }

  Future<List<WalletTransactionModel>> getTransactions(
      {int page = 1, int limit = 20}) async {
    if (Get.isRegistered<AuthService>() && !AuthService.to.isPlayer) {
      return [];
    }

    try {
      final response =
          await remoteDataSource.getTransactions(page: page, limit: limit);
      final list = response.data ?? [];
      if (list.isNotEmpty) {
        await saveLocalCachedTransactions(list);
      }
      return list;
    } catch (e) {
      AppLogger.warning('Network error fetching transactions, loading local storage cache: $e');
      final cached = await getLocalCachedTransactions();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<WalletTransactionModel>> getLocalCachedTransactions() async {
    try {
      if (Get.isRegistered<DatabaseService>()) {
        final dbService = Get.find<DatabaseService>();
        final jsonStr = await dbService.getCachedData(_cacheKey);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final List listData = jsonDecode(jsonStr) as List;
          return listData
              .map((e) =>
                  WalletTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load local cached transactions: $e');
    }
    return [];
  }

  Future<void> saveLocalCachedTransactions(
      List<WalletTransactionModel> txs) async {
    try {
      if (Get.isRegistered<DatabaseService>()) {
        final dbService = Get.find<DatabaseService>();
        final jsonStr = jsonEncode(txs.map((e) => e.toJson()).toList());
        await dbService.cacheData(_cacheKey, jsonStr);
      }
    } catch (e) {
      AppLogger.warning('Failed to save local cached transactions: $e');
    }
  }

  Future<void> setupPin(String pin) async {
    await remoteDataSource.setupPin(pin);
  }

  Future<void> changePin(String oldPin, String newPin) async {
    await remoteDataSource.changePin(oldPin, newPin);
  }

  Future<void> verifyPin(String pin) async {
    await remoteDataSource.verifyPin(pin);
  }
}
