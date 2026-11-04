import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_game_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/payment_processing_overlay.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/error_handler.dart';

class GameCheckoutView extends StatelessWidget {
  const GameCheckoutView({super.key});

  CreateGameController get controller =>
      Get.isRegistered<CreateGameController>()
          ? Get.find<CreateGameController>()
          : Get.put(CreateGameController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    final fee = controller.pitchBookingAmount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pitch Booking Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 950),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 16,
                        vertical: 16,
                      ),
                      child: isWide
                          ? _buildWideTwoColumnLayout(context, fee)
                          : _buildMobileSingleColumnLayout(context, fee),
                    );
                  },
                ),
              ),
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

  Widget _buildMobileSingleColumnLayout(BuildContext context, double fee) {
    return Column(
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
        const SizedBox(height: 24),
        Obx(
          () {
            final isOnline = Get.isRegistered<ConnectivityService>()
                ? ConnectivityService.to.isConnected.value
                : true;
            return AppButton(
              text: !isOnline
                  ? 'No Internet • Connect to Pay'
                  : 'Confirm & Book Pitch • ₹${fee.toStringAsFixed(0)}',
              isLoading: controller.isProcessing.value,
              onPressed: () {
                if (!isOnline) {
                  ErrorHandler.showErrorSnackBar(
                    'No Internet Connection',
                    'Cannot confirm payment without an active internet connection. Please check your network and try again.',
                  );
                  return;
                }
                controller.executePaymentAndCreateGame();
              },
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWideTwoColumnLayout(BuildContext context, double fee) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Pitch Summary & Pricing Breakdown
        Expanded(
          flex: 5,
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
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column: Payment Method & Action Button
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
              Obx(
                () {
                  final isOnline = Get.isRegistered<ConnectivityService>()
                      ? ConnectivityService.to.isConnected.value
                      : true;
                  return AppButton(
                    text: !isOnline
                        ? 'No Internet • Connect to Pay'
                        : 'Confirm & Book Pitch • ₹${fee.toStringAsFixed(0)}',
                    isLoading: controller.isProcessing.value,
                    onPressed: () {
                      if (!isOnline) {
                        ErrorHandler.showErrorSnackBar(
                          'No Internet Connection',
                          'Cannot confirm payment without an active internet connection. Please check your network and try again.',
                        );
                        return;
                      }
                      controller.executePaymentAndCreateGame();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
                  sportTitle == 'Padel'
                      ? Icons.sports_tennis_rounded
                      : Icons.sports_tennis_rounded,
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
                      '$surface • ${sportTitle == 'Padel' ? 'Padel Court' : 'Pickle Pitch'}',
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      dateFormatted,
                      style:
                          TextStyle(fontSize: 12, color: context.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      timeRange,
                      style:
                          TextStyle(fontSize: 12, color: context.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
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
}
