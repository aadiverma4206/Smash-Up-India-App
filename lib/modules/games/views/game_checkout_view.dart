import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_game_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/payment_processing_overlay.dart';
import '../../../core/utils/app_date_utils.dart';

class GameCheckoutView extends GetView<CreateGameController> {
  const GameCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final fee = controller.pitchBookingAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pitch Booking Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pitch Reservation Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPitchSummaryCard(context),
                const SizedBox(height: 20),
                Text(
                  'Pricing Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPricingSummaryCard(context, fee),
                const SizedBox(height: 20),
                Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPaymentMethodsCard(context, fee),
                const SizedBox(height: 20),
                _buildTestModeNoticeCard(context),
                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    text: 'Confirm & Book Pitch • ₹${fee.toStringAsFixed(0)}',
                    isLoading: controller.isProcessing.value,
                    onPressed: controller.executePaymentAndCreateGame,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bolt_rounded, color: Colors.amber),
                  label: const Text(
                    '⚡ Quick Test Payment (Instant Success)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.processTestModePayment,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Obx(
            () => PaymentProcessingOverlay(
              isVisible: controller.isProcessing.value,
              statusText: controller.paymentStatus.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSummaryCard(BuildContext context) {
    final court = controller.selectedCourt.value;
    final courtName = court?.name ?? 'Court 1';
    final sportTitle = controller.selectedGameTitle.value;
    final surface = court?.surfaceType ?? '3G Turf';

    final dateFormatted = controller.selectedDate.value != null
        ? AppDateUtils.formatDate(controller.selectedDate.value!,
            format: 'EEEE, dd MMM yyyy')
        : 'Selected Date';
    final timeRange =
        (controller.startTime.value != null && controller.endTime.value != null)
            ? AppDateUtils.formatTimeRange(
                controller.startTime.value!, controller.endTime.value!)
            : 'Selected Time';
    final duration = controller.durationMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sportTitle == 'Basketball'
                      ? Icons.sports_basketball_rounded
                      : Icons.sports_soccer_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sportTitle • $courtName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$surface • ${sportTitle == 'Basketball' ? 'Basketball Court' : 'Turf Pitch'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: context.borderColor, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(dateFormatted,
                      style:
                          TextStyle(fontSize: 12, color: context.textPrimary)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(timeRange,
                      style:
                          TextStyle(fontSize: 12, color: context.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$courtName Slot',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$duration mins (${(duration / 60.0).toStringAsFixed(1)} hrs)',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummaryCard(BuildContext context, double fee) {
    final court = controller.selectedCourt.value;
    final hourlyRate = court?.basePricePerHour ?? 1200.0;
    final duration = controller.durationMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pitch Hourly Rate',
                  style: TextStyle(color: context.textSecondary, fontSize: 13)),
              Text('₹${hourlyRate.toStringAsFixed(0)} / hr',
                  style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration ($duration mins)',
                  style: TextStyle(color: context.textSecondary, fontSize: 13)),
              Text('${(duration / 60.0).toStringAsFixed(1)} hrs',
                  style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arena Maintenance & Lights',
                  style: TextStyle(color: context.textSecondary, fontSize: 13)),
              const Text('₹0 (Included)',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          Divider(color: context.borderColor, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount Payable',
                  style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('₹${fee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard(BuildContext context, double fee) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Obx(() {
        final selected = controller.selectedPaymentMethod.value;

        return Column(
          children: [
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => controller.selectedPaymentMethod.value = 'RAZORPAY',
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      selected == 'RAZORPAY'
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected == 'RAZORPAY'
                          ? AppColors.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payment_rounded,
                          color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Razorpay Gateway',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'UPI, Credit / Debit Cards, NetBanking',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: context.borderColor, height: 1),
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () => controller.selectedPaymentMethod.value = 'WALLET',
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      selected == 'WALLET'
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected == 'WALLET'
                          ? AppColors.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arena Player Wallet',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Obx(() {
                            final balance = controller.walletBalance.value;
                            final hasSufficient = balance >= fee;
                            return Text(
                              'Available Balance: ₹${balance.toStringAsFixed(0)} ${hasSufficient ? "(Sufficient)" : "(Insufficient)"}',
                              style: TextStyle(
                                color: hasSufficient
                                    ? AppColors.primary
                                    : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTestModeNoticeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Test Environment: You can use the Quick Test Payment button below for immediate simulation, or proceed with standard Razorpay test checkout.',
              style: TextStyle(color: context.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
