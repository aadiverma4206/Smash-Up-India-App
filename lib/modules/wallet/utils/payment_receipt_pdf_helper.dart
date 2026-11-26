import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/utils/app_logger.dart';

class PaymentReceiptPdfHelper {
  static bool _isProcessing = false;

  static bool isWalletPayment(WalletTransactionModel tx) {
    final typeUpper = tx.transactionType.toUpperCase();
    final descLower = tx.description.toLowerCase();

    if (typeUpper == 'MATCH_JOIN' ||
        typeUpper == 'BOOKING_WALLET' ||
        typeUpper == 'DEBIT' ||
        descLower.contains('paid via wallet') ||
        descLower.contains('wallet balance')) {
      return true;
    }
    if (typeUpper == 'TOPUP' ||
        typeUpper == 'RAZORPAY_BOOKING' ||
        typeUpper == 'DIRECT_BOOKING' ||
        descLower.contains('razorpay')) {
      return false;
    }
    return tx.providerPaymentId == null || tx.providerPaymentId!.isEmpty;
  }

  static String getPaymentPurpose(WalletTransactionModel tx) {
    final typeUpper = tx.transactionType.toUpperCase();
    final descLower = tx.description.toLowerCase();

    if (typeUpper == 'REFUND' ||
        typeUpper == 'CANCEL_REFUND' ||
        typeUpper == 'MATCH_REFUND' ||
        typeUpper == 'REFUNDED' ||
        descLower.contains('refund')) {
      return tx.description.isNotEmpty
          ? tx.description
          : 'Match Entry Fee Refunded to Wallet';
    }

    if (descLower.contains('wallet top-up') ||
        descLower.contains('add money') ||
        (typeUpper == 'TOPUP' && !descLower.contains('order'))) {
      return 'Wallet Balance Top-Up';
    }

    if (descLower.contains('pitch') ||
        descLower.contains('turf') ||
        descLower.contains('match') ||
        descLower.contains('booking') ||
        descLower.contains('court') ||
        descLower.contains('slot') ||
        typeUpper == 'RAZORPAY_BOOKING' ||
        typeUpper == 'MATCH_JOIN' ||
        typeUpper == 'DIRECT_BOOKING' ||
        typeUpper == 'PITCH_BOOKING') {
      return tx.description.isNotEmpty
          ? tx.description
          : 'Turf Pitch Slot Booking Fee';
    }

    return tx.description.isNotEmpty ? tx.description : 'Transaction Fee';
  }

  static Future<Uint8List> buildPdfBytes(WalletTransactionModel tx,
      [PdfPageFormat pageFormat = PdfPageFormat.a4]) async {
    final pdf = pw.Document();

    final isWallet = isWalletPayment(tx);
    final paymentMethodStr =
        isWallet ? 'Smash Up India Player Wallet' : 'Razorpay Payment Gateway';
    final purposeStr = getPaymentPurpose(tx);

    String formattedDate = tx.createdAt;
    try {
      final parsedDate = DateTime.tryParse(tx.createdAt)?.toLocal();
      if (parsedDate != null) {
        formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(parsedDate);
      }
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal900,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SMASH UP INDIA',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Official Digital Payment Receipt & Slip',
                          style: const pw.TextStyle(
                            color: PdfColors.teal100,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'RECEIPT SLIP',
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Amount & Status Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AMOUNT PAID',
                          style: pw.TextStyle(
                            color: PdfColors.grey700,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'INR ${tx.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: tx.status.toUpperCase() == 'SUCCESS' ||
                                tx.status.toUpperCase() == 'COMPLETED'
                            ? PdfColors.green100
                            : PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: tx.status.toUpperCase() == 'SUCCESS' ||
                                  tx.status.toUpperCase() == 'COMPLETED'
                              ? PdfColors.green
                              : PdfColors.orange,
                        ),
                      ),
                      child: pw.Text(
                        tx.status.toUpperCase(),
                        style: pw.TextStyle(
                          color: tx.status.toUpperCase() == 'SUCCESS' ||
                                  tx.status.toUpperCase() == 'COMPLETED'
                              ? PdfColors.green900
                              : PdfColors.orange900,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Section Label
              pw.Text(
                'PAYMENT BREAKDOWN & PARTICULARS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 10),

              // Table of Details
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                children: [
                  _buildPdfRow('Payment Reason / Purpose', purposeStr,
                      isBold: true),
                  _buildPdfRow('Payment Method (Paid Via)', paymentMethodStr,
                      isHighlight: true),
                  _buildPdfRow('Transaction ID', tx.id),
                  if (tx.referenceId != null && tx.referenceId!.isNotEmpty)
                    _buildPdfRow('Reference / Order ID', tx.referenceId!),
                  if (tx.providerPaymentId != null &&
                      tx.providerPaymentId!.isNotEmpty)
                    _buildPdfRow('Razorpay Payment ID', tx.providerPaymentId!),
                  _buildPdfRow('Date & Time', formattedDate),
                  _buildPdfRow('Wallet Balance After',
                      'INR ${tx.balanceAfter.toStringAsFixed(2)}'),
                  _buildPdfRow('Issuer', 'Smash Up India Sports Management'),
                ],
              ),

              pw.SizedBox(height: 36),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Footer Note
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Smash Up India Sports Technologies',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        'Computer Generated Slip - Valid without physical signature',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Text(
                    'VERIFIED RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndSharePdf(
      BuildContext context, WalletTransactionModel tx) async {
    if (_isProcessing || Get.isDialogOpen == true) return;
    _isProcessing = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final pdfBytes = await buildPdfBytes(tx);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Smash_Up_India_Receipt_${tx.id}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

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
                  // Icon & Close Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.redAccent,
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

                  // Title & Subtitle
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PDF Receipt Generated',
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
                      'Tx ID: #${tx.id}',
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
                  const SizedBox(height: 14),

                  // Summary Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            getPaymentPurpose(tx),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons Row
                  Row(
                    children: [
                      // View PDF
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Get.back();
                            try {
                              final result = await OpenFilex.open(filePath);
                              if (result.type != ResultType.done) {
                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async =>
                                      pdfBytes,
                                  name: fileName,
                                );
                              }
                            } catch (e) {
                              AppLogger.warning('OpenFilex error: $e');
                            }
                          },
                          icon: const Icon(Icons.remove_red_eye_rounded,
                              size: 16),
                          label: const Text('Open'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share / Print PDF
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Get.back();
                            try {
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename: fileName,
                              );
                            } catch (e) {
                              AppLogger.warning('Printing.sharePdf error: $e');
                            }
                          },
                          icon: const Icon(Icons.share_rounded,
                              size: 16, color: Colors.white),
                          label: const Text('Share',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
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
    } catch (e) {
      AppLogger.error('Failed to generate PDF receipt: $e');
      Get.snackbar(
        'PDF Generation Error',
        'Could not generate PDF receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isProcessing = false;
    }
  }

  static pw.TableRow _buildPdfRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? PdfColors.teal900 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
