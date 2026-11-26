import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/wallet_models.dart';
import '../../../app/theme/app_colors.dart';
import '../utils/payment_receipt_pdf_helper.dart';
import '../utils/payment_receipt_excel_helper.dart';

class PlayerPaymentDetailView extends StatelessWidget {
  final WalletTransactionModel? transaction;

  const PlayerPaymentDetailView({super.key, this.transaction});

  WalletTransactionModel get _tx {
    if (transaction != null) return transaction!;
    final args = Get.arguments;
    if (args is WalletTransactionModel) return args;
    throw Exception('No transaction model provided to PlayerPaymentDetailView');
  }

  @override
  Widget build(BuildContext context) {
    late final WalletTransactionModel tx;
    try {
      tx = _tx;
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(
          child: Text('Transaction details not available.'),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWallet = PaymentReceiptPdfHelper.isWalletPayment(tx);
    final purpose = PaymentReceiptPdfHelper.getPaymentPurpose(tx);

    String formattedDate = tx.createdAt;
    try {
      final parsedDate = DateTime.tryParse(tx.createdAt)?.toLocal();
      if (parsedDate != null) {
        formattedDate =
            DateFormat('EEEE, dd MMMM yyyy, h:mm a').format(parsedDate);
      }
    } catch (_) {}

    final typeUpper = tx.transactionType.toUpperCase();
    final isRefund = typeUpper.contains('REFUND');
    final isTopup = typeUpper == 'TOPUP' || typeUpper == 'CREDIT';

    Color themeAccentColor = isRefund
        ? const Color(0xFF00BFA5)
        : isTopup
            ? const Color(0xFF00C853)
            : const Color(0xFFE53935);

    String amountPrefix = isRefund || isTopup ? '+ ' : '- ';

    final hasUniqueReferenceId = tx.referenceId != null &&
        tx.referenceId!.trim().isNotEmpty &&
        tx.referenceId!.trim() != tx.id.trim();

    final hasProviderPaymentId = tx.providerPaymentId != null &&
        tx.providerPaymentId!.trim().isNotEmpty &&
        tx.providerPaymentId!.trim() != tx.id.trim();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.sageGreenAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transaction Receipt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth < 360 ? 15 : 17,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            const Text(
              'SMASH UP INDIA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          // PDF Option
          IconButton(
            tooltip: 'Download PDF Receipt',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent, size: 18),
            ),
            onPressed: () =>
                PaymentReceiptPdfHelper.generateAndSharePdf(context, tx),
          ),
          // Excel Option
          IconButton(
            tooltip: 'Export Excel Data',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_chart_rounded,
                  color: Colors.green, size: 18),
            ),
            onPressed: () =>
                PaymentReceiptExcelHelper.generateAndExportExcel(context, tx),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Amount & Status Header Card
                      _buildAmountHeaderCard(
                          context, tx, themeAccentColor, amountPrefix),

                      const SizedBox(height: 14),

                      // 2. Purpose & Method Card
                      _buildPurposeAndMethodCard(
                          context, tx, purpose, isWallet),

                      const SizedBox(height: 14),

                      // 3. Technical Identifiers & Ledger Card
                      _buildMetadataCard(
                        context,
                        tx,
                        formattedDate,
                        isWallet: isWallet,
                        isRefund: isRefund,
                        isTopup: isTopup,
                        hasUniqueReferenceId: hasUniqueReferenceId,
                        hasProviderPaymentId: hasProviderPaymentId,
                      ),

                      const SizedBox(height: 20),

                      // 4. Action Buttons
                      _buildActionButtonsRow(context, tx, constraints.maxWidth),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmountHeaderCard(
    BuildContext context,
    WalletTransactionModel tx,
    Color accentColor,
    String prefix,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = tx.status.toUpperCase() == 'SUCCESS' ||
        tx.status.toUpperCase() == 'COMPLETED' ||
        tx.status.toUpperCase() == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SMASH UP INDIA OFFICIAL RECEIPT',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Responsive Fitted Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$prefix₹${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSuccess
                  ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
                  : (isDark
                      ? const Color(0xFF3B1E1E)
                      : const Color(0xFFFFEBEE)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSuccess
                    ? const Color(0xFF00C853).withValues(alpha: 0.4)
                    : Colors.redAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 13,
                  color: isSuccess ? const Color(0xFF00C853) : Colors.redAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSuccess
                        ? (isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF2E7D32))
                        : Colors.redAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeAndMethodCard(
    BuildContext context,
    WalletTransactionModel tx,
    String purpose,
    bool isWallet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment Purpose & Method',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // 1. Kis liye pay kiya (Purpose)
          _buildDetailTile(
            context,
            icon: Icons.assignment_outlined,
            iconColor: Colors.blueAccent,
            title: 'Payment For (Purpose)',
            subtitle: purpose,
            subtitleBold: true,
          ),

          const SizedBox(height: 12),

          // 2. Wallet vs Razorpay (Method)
          _buildDetailTile(
            context,
            icon: isWallet
                ? Icons.account_balance_wallet_rounded
                : Icons.credit_card_rounded,
            iconColor: isWallet ? const Color(0xFFE65100) : Colors.indigoAccent,
            title: 'Paid Via (Payment Method)',
            subtitle: isWallet
                ? 'Smash Up India Player Wallet (Wallet Balance)'
                : 'Razorpay Payment Gateway (Online UPI/Card/NetBanking)',
            badgeLabel: isWallet ? 'WALLET' : 'RAZORPAY',
            badgeColor: isWallet ? Colors.orange : Colors.indigo,
            subtitleBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    WalletTransactionModel tx,
    String formattedDate, {
    required bool isWallet,
    required bool isRefund,
    required bool isTopup,
    required bool hasUniqueReferenceId,
    required bool hasProviderPaymentId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaction Identifiers & Ledger',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Transaction ID
          _buildCopyableField(
            context,
            label: 'Transaction ID',
            value: tx.id,
          ),
          const SizedBox(height: 10),

          // Reference ID
          if (hasUniqueReferenceId) ...[
            _buildCopyableField(
              context,
              label: 'Reference / Order ID',
              value: tx.referenceId!,
            ),
            const SizedBox(height: 10),
          ],

          // Razorpay Payment ID
          if (hasProviderPaymentId) ...[
            _buildCopyableField(
              context,
              label: 'Razorpay Payment ID',
              value: tx.providerPaymentId!,
            ),
            const SizedBox(height: 10),
          ],

          // Date & Time
          _buildDetailRow(
            context,
            label: 'Date & Time',
            value: formattedDate,
          ),

          // Wallet Balance / Settlement Mode
          if (isWallet || isRefund || isTopup) ...[
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              label: 'Wallet Balance After',
              value: '₹${tx.balanceAfter.toStringAsFixed(2)}',
              valueColor: AppColors.primary,
            ),
          ] else ...[
            const SizedBox(height: 10),
            _buildDetailRow(
              context,
              label: 'Settlement Mode',
              value: 'Direct Online Payment',
              valueColor: Colors.indigoAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(
      BuildContext context, WalletTransactionModel tx, double maxWidth) {
    final isNarrow = maxWidth < 360;

    final pdfButton = ElevatedButton.icon(
      onPressed: () => PaymentReceiptPdfHelper.generateAndSharePdf(context, tx),
      icon: const Icon(Icons.picture_as_pdf_rounded,
          color: Colors.white, size: 18),
      label: const Text(
        'PDF Receipt',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final excelButton = ElevatedButton.icon(
      onPressed: () =>
          PaymentReceiptExcelHelper.generateAndExportExcel(context, tx),
      icon:
          const Icon(Icons.table_chart_rounded, color: Colors.white, size: 18),
      label: const Text(
        'Excel Export',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: pdfButton),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: excelButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: pdfButton),
        const SizedBox(width: 12),
        Expanded(child: excelButton),
      ],
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeLabel,
    Color? badgeColor,
    bool subtitleBold = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (badgeLabel != null && badgeColor != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      subtitleBold ? FontWeight.bold : FontWeight.normal,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          icon: const Icon(Icons.copy_rounded,
              size: 17, color: AppColors.primary),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            Get.snackbar(
              'Copied to Clipboard',
              '$label copied: $value',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
          tooltip: 'Copy $label',
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: valueColor ??
                  (isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A)),
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
