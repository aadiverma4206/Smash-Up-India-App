import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/errors/error_handler.dart';

class ManagerPlayerDetailView extends StatefulWidget {
  const ManagerPlayerDetailView({super.key});

  @override
  State<ManagerPlayerDetailView> createState() =>
      _ManagerPlayerDetailViewState();
}

class _ManagerPlayerDetailViewState extends State<ManagerPlayerDetailView> {
  late final ManagerDashboardController controller;
  late String playerId;
  Map<String, dynamic>? initialPlayer;

  final RxString selectedHistoryFilter = 'ALL'.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ManagerDashboardController>();

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      playerId = (args['playerId'] ?? args['id'] ?? '').toString();
      initialPlayer = args['player'] as Map<String, dynamic>?;
    } else if (args is String) {
      playerId = args;
    } else {
      playerId = '';
    }

    if (playerId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchPlayerDetailHistory(playerId);
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty || text == 'N/A') return;
    Clipboard.setData(ClipboardData(text: text));
    ErrorHandler.showSuccessSnackBar(
      'Copied',
      '$label ($text) copied to clipboard.',
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyToClipboard(phoneNumber, 'Phone Number');
      }
    } catch (_) {
      _copyToClipboard(phoneNumber, 'Phone Number');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Player Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isActionLoading.value &&
              controller.selectedPlayerDetail.value == null) {
            return const AppLoader(
                message: 'Loading player history & stats...');
          }

          final detailData = controller.selectedPlayerDetail.value;
          final playerMap = detailData?['player'] as Map<String, dynamic>? ??
              initialPlayer ??
              {};
          final statsMap = detailData?['stats'] as Map<String, dynamic>? ?? {};
          final historyList =
              (detailData?['matchHistory'] as List<dynamic>?) ?? [];

          if (playerMap.isEmpty && detailData == null) {
            return _buildNotFoundState(context);
          }

          final String name = (playerMap['name'] ?? 'Player').toString();
          final String phone = (playerMap['phone'] ?? '').toString();
          final String email = (playerMap['email'] ?? '').toString();
          final String city = (playerMap['city'] ?? '').toString();
          final String bio = (playerMap['bio'] ?? '').toString();
          final bool isBlocked =
              (playerMap['status']?.toString().toUpperCase() == 'BLOCKED') ||
                  (playerMap['status']?.toString().toUpperCase() ==
                      'SUSPENDED') ||
                  (playerMap['isBlocked'] == true);
          final String? avatarUrl = (playerMap['profile_image_url'] ??
                  playerMap['avatarUrl'] ??
                  playerMap['profileImageUrl'] ??
                  playerMap['avatar_url'] ??
                  playerMap['image'] ??
                  playerMap['profile_image'] ??
                  playerMap['picture'] ??
                  playerMap['avatar'])
              ?.toString()
              .resolvedImageUrl;

          final filteredHistory = historyList.where((item) {
            final match = item as Map<String, dynamic>;
            final status = (match['match_status'] ?? match['status'] ?? '')
                .toString()
                .toUpperCase();
            if (selectedHistoryFilter.value == 'ALL') return true;
            if (selectedHistoryFilter.value == 'COMPLETED') {
              return status == 'COMPLETED';
            }
            if (selectedHistoryFilter.value == 'SCHEDULED') {
              return status == 'SCHEDULED' ||
                  status == 'ONGOING' ||
                  status == 'UPCOMING';
            }
            if (selectedHistoryFilter.value == 'CANCELLED') {
              return status == 'CANCELLED';
            }
            return true;
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              if (playerId.isNotEmpty) {
                await controller.fetchPlayerDetailHistory(playerId);
              }
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildHeroProfileCard(
                  context: context,
                  isDark: isDark,
                  name: name,
                  phone: phone,
                  email: email,
                  city: city,
                  bio: bio,
                  isBlocked: isBlocked,
                  avatarUrl: avatarUrl,
                  playerId: playerId,
                ),
                const SizedBox(height: 20),
                _buildMetricsSection(
                  context: context,
                  isDark: isDark,
                  statsMap: statsMap,
                ),
                const SizedBox(height: 24),
                _buildHistoryHeader(
                  context: context,
                  isDark: isDark,
                  totalMatches: historyList.length,
                ),
                const SizedBox(height: 12),
                _buildHistoryFilterTabs(context, isDark, historyList),
                const SizedBox(height: 14),
                if (filteredHistory.isEmpty) ...[
                  _buildEmptyHistoryCard(context, isDark),
                ] else ...[
                  ...filteredHistory.map((matchData) {
                    final match = matchData as Map<String, dynamic>;
                    return _buildHistoryMatchCard(context, isDark, match);
                  }),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeroProfileCard({
    required BuildContext context,
    required bool isDark,
    required String name,
    required String phone,
    required String email,
    required String city,
    required String bio,
    required bool isBlocked,
    required String? avatarUrl,
    required String playerId,
  }) {
    final cardBg = Theme.of(context).cardColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked
              ? Colors.redAccent.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isBlocked ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Top-Right Status Badge
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isBlocked
                    ? Colors.redAccent.withValues(alpha: 0.12)
                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBlocked ? Colors.redAccent : const Color(0xFF10B981),
                  width: 1.2,
                ),
              ),
              child: Text(
                isBlocked ? 'BLOCKED' : 'ACTIVE',
                style: TextStyle(
                  color: isBlocked ? Colors.redAccent : const Color(0xFF10B981),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Main Centered Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Centered Avatar with Instagram Story Gradient Ring
              Center(
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isBlocked
                          ? [Colors.redAccent, Colors.red.shade900]
                          : [
                              const Color(0xFFF09433),
                              const Color(0xFFE6683C),
                              const Color(0xFFDC2743),
                              const Color(0xFFCC2366),
                              const Color(0xFFBC1888),
                            ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(38),
                          child: avatarUrl.isValidNetworkUrl
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl!,
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 76,
                                    height: 76,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      _buildDefaultAvatar(name, size: 76),
                                )
                              : _buildDefaultAvatar(name, size: 76),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isBlocked
                                  ? Colors.redAccent
                                  : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: Icon(
                              isBlocked
                                  ? Icons.close_rounded
                                  : Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Centered Player Name
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              // Centered Location Info
              if (city.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Centered Contact Details Pills (Phone & Email)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty)
                    InkWell(
                      onTap: () => _makePhoneCall(phone),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () =>
                                  _copyToClipboard(phone, 'Phone Number'),
                              child: Icon(Icons.copy_rounded,
                                  size: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (email.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size: 13, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () =>
                                _copyToClipboard(email, 'Email Address'),
                            child: Icon(Icons.copy_rounded,
                                size: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  if (phone.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            foregroundColor: textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _makePhoneCall(phone),
                          icon: const Icon(Icons.call_rounded,
                              size: 15, color: AppColors.primary),
                          label: const Text(
                            'Call Player',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: isBlocked
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () =>
                                  _confirmUnblock(context, playerId, name),
                              icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 15),
                              label: const Text(
                                'UNBLOCK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFEF4444), width: 1.2),
                                foregroundColor: const Color(0xFFEF4444),
                                backgroundColor: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () =>
                                  _showBlockModal(context, playerId, name),
                              icon: const Icon(Icons.block_rounded, size: 15),
                              label: const Text(
                                'BLOCK PLAYER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection({
    required BuildContext context,
    required bool isDark,
    required Map<String, dynamic> statsMap,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);

    final totalMatches = statsMap['totalMatches'] ?? 0;
    final totalPaid = statsMap['totalPaid'] ?? 0;
    final cancelledMatches = statsMap['cancelledMatches'] ?? 0;
    final totalRefunded = statsMap['totalRefunded'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Activity Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatMetricCard(
              context: context,
              isDark: isDark,
              title: 'Matches Played',
              value: '$totalMatches',
              icon: Icons.sports_soccer_rounded,
              color: const Color(0xFF10B981),
            ),
            _buildStatMetricCard(
              context: context,
              isDark: isDark,
              title: 'Total Paid',
              value: '₹$totalPaid',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF0284C7),
            ),
            _buildStatMetricCard(
              context: context,
              isDark: isDark,
              title: 'Cancelled Matches',
              value: '$cancelledMatches',
              icon: Icons.cancel_outlined,
              color: const Color(0xFFEF4444),
            ),
            _buildStatMetricCard(
              context: context,
              isDark: isDark,
              title: 'Amount Refunded',
              value: '₹$totalRefunded',
              icon: Icons.replay_circle_filled_rounded,
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatMetricCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader({
    required BuildContext context,
    required bool isDark,
    required int totalMatches,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Match & Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalMatches',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryFilterTabs(
    BuildContext context,
    bool isDark,
    List<dynamic> allMatches,
  ) {
    int completedCount = 0;
    int scheduledCount = 0;
    int cancelledCount = 0;

    for (var item in allMatches) {
      final match = item as Map<String, dynamic>;
      final status = (match['match_status'] ?? match['status'] ?? '')
          .toString()
          .toUpperCase();
      if (status == 'COMPLETED') {
        completedCount++;
      } else if (status == 'CANCELLED') {
        cancelledCount++;
      } else {
        scheduledCount++;
      }
    }

    final filters = [
      {'key': 'ALL', 'label': 'All', 'count': allMatches.length},
      {'key': 'COMPLETED', 'label': 'Completed', 'count': completedCount},
      {'key': 'SCHEDULED', 'label': 'Upcoming', 'count': scheduledCount},
      {'key': 'CANCELLED', 'label': 'Cancelled', 'count': cancelledCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((tab) {
          final filterKey = tab['key'] as String;
          final label = tab['label'] as String;
          final count = tab['count'] as int;

          return Obx(() {
            final isSelected = selectedHistoryFilter.value == filterKey;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => selectedHistoryFilter.value = filterKey,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? AppColors.darkInputBg
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryMatchCard(
      BuildContext context, bool isDark, Map<String, dynamic> match) {
    final cardBg = Theme.of(context).cardColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    final String gameId = (match['game_id'] ?? match['id'] ?? '').toString();
    final String title =
        (match['game_title'] ?? match['title'] ?? 'Turf Match').toString();
    final String format = (match['format'] ?? '5v5').toString();
    final String courtName = (match['court_name'] ?? 'Main Pitch').toString();
    final String clubName = (match['club_name'] ?? '').toString();
    final String team = (match['team'] ?? '').toString();
    final String gamePosition = (match['game_position'] ?? '').toString();
    final String videoUrl = (match['video_url'] ?? '').toString();
    final String matchStatus =
        (match['match_status'] ?? match['status'] ?? 'COMPLETED')
            .toString()
            .toUpperCase();
    final String paymentStatus =
        (match['payment_status'] ?? 'PAID').toString().toUpperCase();
    final double entryFee =
        double.tryParse(match['entry_fee']?.toString() ?? '0') ?? 0.0;

    String dateStr = '';
    if (match['match_date'] != null) {
      dateStr = AppDateUtils.formatDate(match['match_date']);
    }
    final String startTime = (match['start_time'] ?? '').toString();
    final String endTime = (match['end_time'] ?? '').toString();

    String timeDisplay = dateStr;
    if (startTime.isNotEmpty) {
      timeDisplay =
          '$dateStr  •  $startTime${endTime.isNotEmpty ? ' - $endTime' : ''}';
    }

    Color paymentColor = const Color(0xFF00C853);
    if (paymentStatus == 'REFUNDED') {
      paymentColor = const Color(0xFFD97706);
    } else if (paymentStatus == 'PENDING') {
      paymentColor = const Color(0xFF64748B);
    } else if (paymentStatus == 'FAILED') {
      paymentColor = const Color(0xFFEF4444);
    }

    Color matchStatusColor = AppColors.primary;
    if (matchStatus == 'CANCELLED') {
      matchStatusColor = const Color(0xFFEF4444);
    } else if (matchStatus == 'COMPLETED') {
      matchStatusColor = const Color(0xFF00C853);
    } else if (matchStatus == 'SCHEDULED' || matchStatus == 'UPCOMING') {
      matchStatusColor = const Color(0xFF0284C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (gameId.isNotEmpty) {
              Get.toNamed(Routes.gameDetails, arguments: gameId);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  format.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  courtName +
                                      (clubName.isNotEmpty
                                          ? '  •  $clubName'
                                          : ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: matchStatusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: matchStatusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        matchStatus,
                        style: TextStyle(
                          color: matchStatusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (timeDisplay.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (team.isNotEmpty || gamePosition.isNotEmpty) ...[
                  Row(
                    children: [
                      if (team.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkInputBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Team: $team',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (gamePosition.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkInputBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Position: $gamePosition',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment_rounded,
                            size: 15, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Entry Fee: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '₹${entryFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (videoUrl.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.videocam_rounded,
                                    size: 12, color: Colors.purple),
                                SizedBox(width: 3),
                                Text(
                                  'CCTV',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: paymentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: paymentColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            paymentStatus,
                            style: TextStyle(
                              color: paymentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyHistoryCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Matches Recorded',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This player has not participated in matches under this category yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded,
                size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'Player Not Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load profile and match history for the requested player.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Player List'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name, {double size = 44}) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showBlockModal(BuildContext context, String playerId, String name) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Block Player: $name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Restricting access will prevent $name from joining matches and booking slots at this turf.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText:
                    'Enter reason for blocking (e.g. misconduct, no-show)...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkInputBg : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Get.back();
                      await controller.blockPlayer(
                          playerId, reasonController.text.trim());
                    },
                    child: const Text(
                      'Confirm Block',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnblock(BuildContext context, String playerId, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF00C853), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unblock Player: $name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to restore match and turf booking access for $name?',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Get.back();
                      await controller.unblockPlayer(playerId);
                    },
                    child: const Text(
                      'Confirm Unblock',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
