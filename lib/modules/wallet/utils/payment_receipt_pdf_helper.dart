import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext, Colors;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/wallet_models.dart';
import '../../../core/utils/app_logger.dart';

class PaymentReceiptPdfHelper {
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
    try {
      final pdfBytes = await buildPdfBytes(tx);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Smash_Up_India_Receipt_${tx.id}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      Get.snackbar(
        'PDF Receipt Saved',
        'Receipt saved: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      try {
        final result = await OpenFilex.open(filePath);
        if (result.type == ResultType.done) {
          return;
        }
      } catch (openError) {
        AppLogger.warning('OpenFilex.open failed: $openError');
      }

      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fileName,
        );
      } catch (printError) {
        AppLogger.warning('Printing.layoutPdf failed: $printError');
        try {
          final fileUri = Uri.file(filePath);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.error('Failed to generate PDF receipt: $e');
      Get.snackbar(
        'PDF Generation Error',
        'Could not generate PDF receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
