// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$WalletBalanceModelToJson(WalletBalanceModel instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'hasPin': instance.hasPin,
      'status': instance.status,
      'maxBalanceLimit': instance.maxBalanceLimit,
      'maxSingleTopup': instance.maxSingleTopup,
    };

Map<String, dynamic> _$RazorpayOrderModelToJson(RazorpayOrderModel instance) =>
    <String, dynamic>{
      'paymentOrderId': instance.paymentOrderId,
      'orderId': instance.orderId,
      'amountPaisa': instance.amountPaisa,
      'currency': instance.currency,
      'keyId': instance.keyId,
    };

Map<String, dynamic> _$WalletTransactionModelToJson(
        WalletTransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transactionType': instance.transactionType,
      'amount': instance.amount,
      'balanceAfter': instance.balanceAfter,
      'description': instance.description,
      'status': instance.status,
      'referenceId': instance.referenceId,
      'providerPaymentId': instance.providerPaymentId,
      'createdAt': instance.createdAt,
    };
