import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/wallet_models.dart';

class WalletRemoteDataSource {
  final DioClient dioClient;

  WalletRemoteDataSource({required this.dioClient});

  Future<ApiResponseModel<WalletBalanceModel>> getWallet() async {
    final response = await dioClient.dio.get(ApiConstants.wallet);
    return ApiResponseParser.parse<WalletBalanceModel>(
      response.data,
      (json) => WalletBalanceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<RazorpayOrderModel>> createTopupOrder(
      double amountRupees, String idempotencyKey,
      {String? walletPin}) async {
    final key = idempotencyKey.length >= 16
        ? idempotencyKey
        : 'idemp_${DateTime.now().millisecondsSinceEpoch}_$idempotencyKey';
    final response = await dioClient.dio.post(
      ApiConstants.walletTopupOrder,
      data: {
        'amountRupees': amountRupees,
        'idempotencyKey': key,
        if (walletPin != null && walletPin.isNotEmpty) 'walletPin': walletPin,
      },
      options: Options(headers: {'x-idempotency-key': key}),
    );
    return ApiResponseParser.parse<RazorpayOrderModel>(
      response.data,
      (json) => RazorpayOrderModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<WalletBalanceModel>> verifyTopupPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? paymentOrderId,
  }) async {
    final response = await dioClient.dio.post(
      ApiConstants.walletTopupVerify,
      data: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        if (paymentOrderId != null && paymentOrderId.isNotEmpty)
          'paymentOrderId': paymentOrderId,
      },
    );
    return ApiResponseParser.parse<WalletBalanceModel>(
      response.data,
      (json) => WalletBalanceModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel<List<WalletTransactionModel>>> getTransactions(
      {int page = 1, int limit = 20}) async {
    final response = await dioClient.dio.get(
      ApiConstants.walletTransactions,
      queryParameters: {'page': page, 'limit': limit},
    );
    return ApiResponseParser.parse<List<WalletTransactionModel>>(
      response.data,
      (json) => (json as List)
          .map(
              (e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> setupPin(String pin) async {
    await dioClient.dio.post(ApiConstants.walletPin, data: {'pin': pin});
  }

  Future<void> changePin(String oldPin, String newPin) async {
    await dioClient.dio.post(
      ApiConstants.walletPinChange,
      data: {'oldPin': oldPin, 'newPin': newPin},
    );
  }

  Future<void> verifyPin(String pin) async {
    await dioClient.dio.post(ApiConstants.walletPinVerify, data: {'pin': pin});
  }
}
