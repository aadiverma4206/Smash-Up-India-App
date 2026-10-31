import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_loader.dart';

class AdminPaymentHistoryView extends GetView<AdminController> {
  AdminPaymentHistoryView({super.key});

  final TextEditingController searchController = TextEditingController();

  String _getDateGroupHeader(String dateStr) {
    final dt = AppDateUtils.parseDateTime(dateStr);
    if (dt == null) return 'Earlier';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (itemDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (itemDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMMM yyyy').format(dt);
    }
  }

  Map<String, List<AdminPaymentModel>> _groupPaymentsByDate(
      List<AdminPaymentModel> list) {
    final Map<String, List<AdminPaymentModel>> grouped = {};
    for (final item in list) {
      final header = _getDateGroupHeader(
          item.createdAt.isNotEmpty ? item.createdAt : (item.matchTime ?? ''));
      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Player Payment History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF0F172A),
            ),
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.sageGreenAppBar,
          iconTheme: IconThemeData(
            color: isDark
                ? AppColors.textPrimaryDark
                : const Color(0xFF0F172A),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchPaymentHistory,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // 1. Summary Header Card
              SliverToBoxAdapter(
                child: _buildSummaryHeaderCard(context),
              ),

              // 2. Search & Filter Chips
              SliverToBoxAdapter(
                child: _buildSearchAndFilters(context),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),

              // 3. Payment Records List (Grouped by Date)
              Obx(() {
                if (controller.isLoadingPayments.value &&
                    controller.payments.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoader(message: 'Loading payment records...'),
                  );
                }

                if (controller.payments.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Payment History Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Player payment and refund records will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = _groupPaymentsByDate(controller.payments);
                final List<Widget> slivers = [];

                for (final entry in grouped.entries) {
                  // Date Section Header
                  slivers.add(
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E8F0),
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.value.length} ${entry.value.length == 1 ? "record" : "records"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  // Payment Cards List for this date
                  slivers.add(
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final payment = entry.value[index];
                            return _buildPaymentCard(context, payment);
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ),
                  );
                }

                return SliverMainAxisGroup(slivers: slivers);
              }),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeaderCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final summary = controller.paymentSummary.value;
      final totalRev = summary?.totalRevenue ?? 0.0;
      final totalRef = summary?.totalRefunds ?? 0.0;
      final netRev = summary?.netRevenue ?? (totalRev + totalRef);

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Net Revenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${netRev.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF00E676),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Gross Revenue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${totalRev.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Total Refunds',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${totalRef.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      {'label': 'All', 'value': 'ALL'},
      {'label': 'Confirmed', 'value': 'CONFIRMED'},
      {'label': 'Cancelled', 'value': 'CANCELLED'},
      {'label': 'Refunded', 'value': 'REFUNDED'},
    ];

    if (searchController.text != controller.paymentSearchQuery.value) {
      searchController.text = controller.paymentSearchQuery.value;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: controller.onPaymentSearchChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: TextStyle(
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search player name, phone or match title...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              suffixIcon: Obx(() {
                if (controller.paymentSearchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.grey, size: 18),
                  onPressed: () {
                    searchController.clear();
                    controller.onPaymentSearchChanged('');
                  },
                );
              }),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: filters.map((f) {
                  final isSelected =
                      controller.selectedPaymentFilter.value == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: isSelected,
                      checkmarkColor: Colors.white,
                      label: Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF475569)),
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : Theme.of(context).cardColor,
                      onSelected: (_) =>
                          controller.setPaymentFilter(f['value'] as String),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, AdminPaymentModel payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCancelled = payment.status == 'CANCELLED';
    final isRefunded = payment.status == 'REFUNDED';
    final isNegative = isCancelled || isRefunded;

    Color statusBgColor =
        isDark ? const Color(0xFF132B1F) : const Color(0xFFE8F8F0);
    Color statusTextColor =
        isDark ? const Color(0xFF00E676) : const Color(0xFF00C853);

    if (isCancelled) {
      statusBgColor =
          isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE);
      statusTextColor =
          isDark ? const Color(0xFFF87171) : const Color(0xFFC62828);
    } else if (isRefunded) {
      statusBgColor =
          isDark ? const Color(0xFF3A2814) : const Color(0xFFFFF3E0);
      statusTextColor =
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFEF6C00);
    }

    final avatarUrl = ImageUtils.resolveImageUrl(payment.userAvatar);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(
              '/admin/payments/detail',
              arguments: payment,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Player info & Amount
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              payment.userName.isNotEmpty
                                  ? payment.userName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.userName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.userPhone.isNotEmpty
                                ? payment.userPhone
                                : payment.userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isNegative ? "-" : "+"}₹${payment.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            payment.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10),

                // Match details & CCTV Video indicator
                Row(
                  children: [
                    Icon(
                      Icons.sports_soccer_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        payment.matchTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (payment.hasVideo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.videocam_rounded,
                                size: 12, color: Colors.red),
                            SizedBox(width: 3),
                            Text(
                              'CCTV Video',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${payment.clubName} • ${payment.courtName}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Score: ${payment.score}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
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
}
