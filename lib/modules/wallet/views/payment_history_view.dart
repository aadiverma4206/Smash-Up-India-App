import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_history_controller.dart';
import '../../../data/models/wallet_models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../app/routes/app_routes.dart';

class PlayerPaymentHistoryView extends GetView<PlayerPaymentHistoryController> {
  const PlayerPaymentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PlayerPaymentHistoryController());
    final searchTextController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed(Routes.home);
              Get.toNamed(Routes.wallet);
            }
          },
        ),
        title: const Text('Transaction History & Records',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              searchTextController.clear();
              controller.setSearchQuery('');
              controller.fetchTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Search Bar
          _buildSearchBar(context, controller, searchTextController),
          const SizedBox(height: 10),
          // Filter Chips
          _buildFilterBar(context, controller),
          const SizedBox(height: 10),
          // Main Grouped List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppLoader(message: 'Loading transaction list...');
              }

              if (controller.groupedTransactions.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const EmptyStateWidget(
                          title: 'No Transactions Found',
                          subtitle:
                              'No payment records found matching your search filter.',
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
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchTransactions,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.groupedTransactions.length,
                  itemBuilder: (context, groupIndex) {
                    final group = controller.groupedTransactions[groupIndex];
                    return _buildGroupSection(context, group);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context,
      PlayerPaymentHistoryController controller,
      TextEditingController searchController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark(context) ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark(context)
                  ? AppColors.darkBorder
                  : Colors.grey.withValues(alpha: 0.3)),
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
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search transactions by description or amount...',
            hintStyle: TextStyle(fontSize: 13, color: context.textSecondary),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, PlayerPaymentHistoryController controller) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.typeFilters.length,
        itemBuilder: (context, index) {
          final filter = controller.typeFilters[index];
          return Obx(() {
            final isSelected = controller.selectedFilter.value == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => controller.setFilter(filter),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark(context)
                            ? AppColors.darkCard
                            : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark(context)
                              ? AppColors.darkBorder
                              : Colors.grey.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildGroupSection(
      BuildContext context, DateGroupedTransactions group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header Card
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark(context)
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEFF4F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark(context)
                    ? AppColors.darkBorder
                    : Colors.blueGrey.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    group.dateHeader,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark(context) ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${group.items.length} ${group.items.length == 1 ? 'Record' : 'Records'}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondary),
                ),
              ),
            ],
          ),
        ),
        // Group Transactions
        ...group.items.map((tx) => _buildTransactionCard(context, tx)),
      ],
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, WalletTransactionModel tx) {
    final typeUpper = tx.transactionType.toUpperCase();
    final isCredit = typeUpper == 'TOPUP' ||
        typeUpper == 'REFUND' ||
        typeUpper == 'CREDIT' ||
        typeUpper == 'DEPOSIT';
    final isRefund = typeUpper == 'REFUND';

    final Color amountColor = isRefund
        ? const Color(0xFF00BFA5)
        : (isCredit ? const Color(0xFF00C853) : const Color(0xFFE53935));

    final IconData iconData = isRefund
        ? Icons.published_with_changes_rounded
        : (isCredit
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded);

    String formattedTime = '';
    try {
      final parsedDate = DateTime.tryParse(tx.createdAt)?.toLocal();
      if (parsedDate != null) {
        formattedTime = DateFormat('h:mm a').format(parsedDate);
      }
    } catch (_) {}

    return Card(
      color: isDark(context) ? AppColors.darkCard : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isDark(context)
                ? AppColors.darkBorder
                : AppColors.primary.withValues(alpha: 0.2)),
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
                        color: amountColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 16, color: amountColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeUpper,
                        style: TextStyle(
                            color: amountColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isCredit ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: amountColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tx.description,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance After: ₹${tx.balanceAfter.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  formattedTime.isNotEmpty ? formattedTime : tx.createdAt,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
