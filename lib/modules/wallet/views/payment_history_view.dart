import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_history_controller.dart';
import '../../../data/models/wallet_models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../app/routes/app_routes.dart';

enum PaymentCategory {
  walletTopup, // Added money to wallet via Razorpay
  pitchBookingRazorpay, // Pitch/Turf booking payment (Red -, NO wallet balance)
  pitchBookingWallet, // Pitch/Turf booking paid via Wallet balance (Shows balance)
  refund, // Match entry fee refund credited to wallet
  other,
}

class PlayerPaymentHistoryView extends GetView<PlayerPaymentHistoryController> {
  const PlayerPaymentHistoryView({super.key});

  PaymentCategory _getPaymentCategory(WalletTransactionModel tx) {
    final typeUpper = tx.transactionType.toUpperCase();
    final descLower = tx.description.toLowerCase();

    // 1. Refund
    if (typeUpper == 'REFUND' ||
        typeUpper == 'CANCEL_REFUND' ||
        typeUpper == 'MATCH_REFUND' ||
        typeUpper == 'REFUNDED' ||
        descLower.contains('refund')) {
      return PaymentCategory.refund;
    }

    // 2. Exact Wallet Add / Top-Up (Adding money to wallet)
    final isExplicitWalletTopup = descLower == 'wallet top-up via razorpay' ||
        descLower == 'wallet top-up' ||
        descLower.contains('wallet top-up via razorpay') ||
        (typeUpper == 'TOPUP' &&
            descLower.contains('via razorpay') &&
            !descLower.contains('order'));

    if (isExplicitWalletTopup) {
      return PaymentCategory.walletTopup;
    }

    // 3. Pitch Booking Payments (e.g., ₹300, ₹100 booking orders, or "Wallet Top-up Order", or direct Razorpay bookings)
    final isPitchBooking = descLower.contains('order') ||
        descLower.contains('pitch') ||
        descLower.contains('turf') ||
        descLower.contains('match') ||
        descLower.contains('booking') ||
        descLower.contains('court') ||
        descLower.contains('slot') ||
        typeUpper == 'RAZORPAY_BOOKING' ||
        typeUpper == 'DIRECT_BOOKING' ||
        typeUpper == 'PITCH_BOOKING';

    if (isPitchBooking) {
      return PaymentCategory.pitchBookingRazorpay;
    }

    // 4. Wallet Pitch Booking
    if (typeUpper == 'MATCH_JOIN' ||
        typeUpper == 'BOOKING_WALLET' ||
        typeUpper == 'DEBIT' ||
        typeUpper == 'PAYMENT') {
      return PaymentCategory.pitchBookingWallet;
    }

    // Fallback for TOPUP / CREDIT
    if (typeUpper == 'TOPUP' ||
        typeUpper == 'CREDIT' ||
        typeUpper == 'DEPOSIT') {
      if (descLower.contains('order')) {
        return PaymentCategory.pitchBookingRazorpay;
      }
      return PaymentCategory.walletTopup;
    }

    return PaymentCategory.pitchBookingRazorpay;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PlayerPaymentHistoryController());
    final searchTextController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.sageGreenAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          'Transaction History & Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
            onPressed: () {
              searchTextController.clear();
              controller.setSearchQuery('');
              controller.fetchTransactions();
            },
            tooltip: 'Refresh Transactions',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildSearchBar(context, controller, searchTextController),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.allTransactions.isEmpty) {
                    return const AppLoader(
                        message: 'Loading transaction records...');
                  }

                  if (controller.groupedTransactions.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const EmptyStateWidget(
                                title: 'No Transactions Found',
                                subtitle:
                                    'No transaction records matching your current filter or search criteria.',
                                icon: Icons.receipt_long_outlined,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  searchTextController.clear();
                                  controller.setSearchQuery('');
                                  controller.setFilter('ALL');
                                  controller.fetchTransactions();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 18),
                                label: const Text('Reset Search & Refresh',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchTransactions,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: controller.groupedTransactions.length,
                      itemBuilder: (context, groupIndex) {
                        final group =
                            controller.groupedTransactions[groupIndex];
                        return _buildGroupSection(context, group);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context,
      PlayerPaymentHistoryController controller,
      TextEditingController searchController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: controller.setSearchQuery,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Search transactions by description or amount...',
            hintStyle: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primary, size: 22),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    searchController.clear();
                    controller.setSearchQuery('');
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(
      BuildContext context, DateGroupedTransactions group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEFF4F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.blueGrey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    group.dateHeader,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${group.items.length} ${group.items.length == 1 ? 'Record' : 'Records'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...group.items.map((tx) => _buildTransactionCard(context, tx)),
      ],
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, WalletTransactionModel tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _getPaymentCategory(tx);

    Color badgeColor;
    String badgeLabel;
    IconData iconData;
    String amountPrefix;
    bool showWalletBalanceAfter;
    String displayDescription;

    switch (category) {
      case PaymentCategory.walletTopup:
        badgeColor = const Color(0xFF00C853); // Bright Green
        badgeLabel = 'WALLET TOP-UP';
        iconData = Icons.add_circle_rounded;
        amountPrefix = '+ ';
        showWalletBalanceAfter = true; // Show balance after for wallet add!
        displayDescription = 'Wallet Top-Up via Razorpay';
        break;

      case PaymentCategory.pitchBookingRazorpay:
        badgeColor = const Color(0xFFE53935); // Red color for Pitch Booking
        badgeLabel = 'PITCH BOOKING';
        iconData = Icons.sports_soccer_rounded;
        amountPrefix = '- ';
        showWalletBalanceAfter = false; // HIDE wallet balance as instructed!
        displayDescription = 'Turf Pitch Slot Booking Payment';
        break;

      case PaymentCategory.pitchBookingWallet:
        badgeColor = const Color(0xFFE65100); // Orange/Red
        badgeLabel = 'PITCH BOOKING (WALLET)';
        iconData = Icons.sports_soccer_rounded;
        amountPrefix = '- ';
        showWalletBalanceAfter = true;
        displayDescription = tx.description.isNotEmpty
            ? tx.description
            : 'Turf Slot Booking (Paid via Wallet)';
        break;

      case PaymentCategory.refund:
        badgeColor = const Color(0xFF00BFA5); // Teal
        badgeLabel = 'MATCH REFUND';
        iconData = Icons.published_with_changes_rounded;
        amountPrefix = '+ ';
        showWalletBalanceAfter = true;
        displayDescription = tx.description.isNotEmpty
            ? tx.description
            : 'Cancelled Match Refunded to Wallet';
        break;

      case PaymentCategory.other:
        badgeColor = const Color(0xFFE53935);
        badgeLabel = 'PITCH BOOKING';
        iconData = Icons.sports_soccer_rounded;
        amountPrefix = '- ';
        showWalletBalanceAfter = false;
        displayDescription = 'Turf Pitch Slot Booking Payment';
        break;
    }

    String formattedTime = '';
    try {
      final parsedDate = DateTime.tryParse(tx.createdAt)?.toLocal();
      if (parsedDate != null) {
        formattedTime = DateFormat('h:mm a').format(parsedDate);
      }
    } catch (_) {}

    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 18, color: badgeColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$amountPrefix₹${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              displayDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showWalletBalanceAfter)
                  Text(
                    'Wallet Balance After: ₹${tx.balanceAfter.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Online payment',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  formattedTime.isNotEmpty ? formattedTime : tx.createdAt,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
