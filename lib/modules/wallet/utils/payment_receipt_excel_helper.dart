import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/utils/app_logger.dart';
import 'payment_receipt_pdf_helper.dart';

class PaymentReceiptExcelHelper {
  static Future<void> generateAndExportExcel(
      BuildContext context, WalletTransactionModel tx) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        if (!context.mounted) return;

        Get.dialog(
          Dialog(
            backgroundColor: Theme.of(context).cardColor,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.table_chart_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Excel Exported',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved: $fileName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Get.back();
                              try {
                                await OpenFilex.open(filePath);
                              } catch (e) {
                                AppLogger.warning('OpenFilex excel error: $e');
                              }
                            },
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('Open File',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to export Excel receipt: $e');
      Get.snackbar(
        'Excel Export Failed',
        'Could not export Excel receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
