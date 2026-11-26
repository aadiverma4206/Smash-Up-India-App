import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' show BuildContext, Colors;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/utils/app_logger.dart';
import 'payment_receipt_pdf_helper.dart';

class PaymentReceiptExcelHelper {
  static Future<void> generateAndExportExcel(
      BuildContext context, WalletTransactionModel tx) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Transaction Receipt';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      String formattedDate = tx.createdAt;
      try {
        final parsedDate = DateTime.tryParse(tx.createdAt)?.toLocal();
        if (parsedDate != null) {
          formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(parsedDate);
        }
      } catch (_) {}

      final isWallet = PaymentReceiptPdfHelper.isWalletPayment(tx);
      final paymentMethodStr = isWallet
          ? 'Smash Up India Player Wallet'
          : 'Razorpay Payment Gateway';
      final purposeStr = PaymentReceiptPdfHelper.getPaymentPurpose(tx);

      // App Title Row
      sheet.appendRow([
        TextCellValue('SMASH UP INDIA - OFFICIAL TRANSACTION RECEIPT SLIP')
      ]);
      sheet.appendRow([
        TextCellValue(
            'Exported Date: ${DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now())}')
      ]);
      sheet.appendRow([TextCellValue('')]); // Blank line

      // Table Headers
      sheet.appendRow([
        TextCellValue('FIELD NAME'),
        TextCellValue('TRANSACTION DETAILS'),
      ]);

      // Data Rows
      sheet.appendRow([TextCellValue('Transaction ID'), TextCellValue(tx.id)]);
      sheet.appendRow([
        TextCellValue('Payment Purpose / Reason'),
        TextCellValue(purposeStr)
      ]);
      sheet.appendRow([
        TextCellValue('Payment Method (Paid Via)'),
        TextCellValue(paymentMethodStr)
      ]);
      sheet.appendRow(
          [TextCellValue('Amount Paid (INR)'), DoubleCellValue(tx.amount)]);
      sheet.appendRow([
        TextCellValue('Transaction Status'),
        TextCellValue(tx.status.toUpperCase())
      ]);
      sheet.appendRow([
        TextCellValue('Reference ID'),
        TextCellValue(tx.referenceId ?? 'N/A')
      ]);
      sheet.appendRow([
        TextCellValue('Razorpay Payment ID'),
        TextCellValue(tx.providerPaymentId ?? 'N/A')
      ]);
      sheet.appendRow([
        TextCellValue('Wallet Balance After (INR)'),
        DoubleCellValue(tx.balanceAfter)
      ]);
      sheet.appendRow([
        TextCellValue('Transaction Date & Time'),
        TextCellValue(formattedDate)
      ]);
      sheet.appendRow([
        TextCellValue('Issuer'),
        TextCellValue('Smash Up India Sports Management System')
      ]);

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'Smash_Up_India_Receipt_${tx.id}.xlsx';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        Get.snackbar(
          'Excel Exported Successfully',
          'Receipt saved to device documents: $fileName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to export Excel receipt: $e');
      Get.snackbar(
        'Excel Export Failed',
        'Could not export Excel receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
