import 'package:json_annotation/json_annotation.dart';

part 'wallet_models.g.dart';

@JsonSerializable(createFactory: false)
class WalletBalanceModel {
  final double balance;
  final bool hasPin;
  final String status;
  final double maxBalanceLimit;
  final double maxSingleTopup;

  WalletBalanceModel({
    required this.balance,
    required this.hasPin,
    this.status = 'ACTIVE',
    this.maxBalanceLimit = 200000.0,
    this.maxSingleTopup = 200000.0,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    final rawPin = json['isPinSet'] ?? json['hasPin'] ?? json['is_pin_set'];
    final bool hasPinValue = (rawPin == true ||
        rawPin?.toString().toLowerCase() == 'true' ||
        rawPin?.toString() == '1' ||
        rawPin?.toString() == 't');

    return WalletBalanceModel(
      balance:
          (json['walletBalance'] ?? json['balance'] as num?)?.toDouble() ?? 0.0,
      hasPin: hasPinValue,
      status: (json['status'] ?? 'ACTIVE') as String,
      maxBalanceLimit:
          (json['maxWalletBalance'] ?? json['maxBalanceLimit'] as num?)
                  ?.toDouble() ??
              200000.0,
      maxSingleTopup: (json['maxSingleTopup'] as num?)?.toDouble() ?? 200000.0,
    );
  }

  Map<String, dynamic> toJson() => _$WalletBalanceModelToJson(this);
}

@JsonSerializable(createFactory: false)
class RazorpayOrderModel {
  final String paymentOrderId;
  final String orderId;
  final int amountPaisa;
  final String currency;
  final String keyId;

  RazorpayOrderModel({
    this.paymentOrderId = '',
    required this.orderId,
    required this.amountPaisa,
    this.currency = 'INR',
    required this.keyId,
  });

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderModel(
      paymentOrderId: (json['paymentOrderId'] ??
          json['payment_order_id'] ??
          json['id'] ??
          '') as String,
      orderId: (json['razorpayOrderId'] ??
          json['orderId'] ??
          json['order_id'] ??
          '') as String,
      amountPaisa: (json['amountPaise'] ??
                  json['amountPaisa'] ??
                  json['amount_paise'] ??
                  json['amount_paisa'] as num?)
              ?.toInt() ??
          0,
      currency: (json['currency'] ?? 'INR') as String,
      keyId: (json['razorpayKeyId'] ?? json['keyId'] ?? json['key_id'] ?? '')
          as String,
    );
  }

  Map<String, dynamic> toJson() => _$RazorpayOrderModelToJson(this);
}

@JsonSerializable(createFactory: false)
class WalletTransactionModel {
  final String id;
  final String transactionType;
  final double amount;
  final double balanceAfter;
  final String description;
  final String status;
  final String? referenceId;
  final String? providerPaymentId;
  final String createdAt;

  WalletTransactionModel({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.status,
    this.referenceId,
    this.providerPaymentId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WalletTransactionModel(
      id: (json['id'] ?? json['transaction_id'] ?? json['tx_id'] ?? '')
          .toString(),
      transactionType: (json['transactionType'] ??
              json['transaction_type'] ??
              json['type'] ??
              'TOPUP')
          .toString(),
      amount: parseDouble(json['amount']),
      balanceAfter: parseDouble(json['balanceAfter'] ?? json['balance_after']),
      description: (json['description'] ?? 'Wallet transaction').toString(),
      status: (json['status'] ?? 'SUCCESS').toString(),
      referenceId:
          json['referenceId']?.toString() ?? json['reference_id']?.toString(),
      providerPaymentId: json['providerPaymentId']?.toString() ??
          json['provider_payment_id']?.toString() ??
          json['razorpay_payment_id']?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => _$WalletTransactionModelToJson(this);
}
