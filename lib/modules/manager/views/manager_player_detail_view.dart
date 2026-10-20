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
      controller.fetchPlayerDetailHistory(playerId);
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
          'Player Profile & History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (playerId.isNotEmpty) {
                controller.fetchPlayerDetailHistory(playerId,
                    forceReload: true);
              }
            },
          ),
        ],
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
          final String position = (playerMap['position'] ?? 'ST').toString();
          final String skillLevel = (playerMap['skill_level'] ?? '').toString();
          final String preferredFoot =
              (playerMap['preferred_foot'] ?? '').toString();
          final int elo = int.tryParse(playerMap['elo_rating']?.toString() ??
                  playerMap['elo']?.toString() ??
                  '750') ??
              750;
          final int ovr =
              int.tryParse(playerMap['ovr_rating']?.toString() ?? '0') ?? 0;
          final bool isBlocked =
              (playerMap['status']?.toString().toUpperCase() == 'BLOCKED') ||
                  (playerMap['status']?.toString().toUpperCase() ==
                      'SUSPENDED') ||
                  (playerMap['isBlocked'] == true);
          final String? avatarUrl =
              playerMap['profile_image_url']?.toString() ??
                  playerMap['avatarUrl']?.toString() ??
                  playerMap['profileImageUrl']?.toString();

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
                  position: position,
                  skillLevel: skillLevel,
                  preferredFoot: preferredFoot,
                  elo: elo,
                  ovr: ovr,
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
    required String position,
    required String skillLevel,
    required String preferredFoot,
    required int elo,
    required int ovr,
    required bool isBlocked,
    required String? avatarUrl,
    required String playerId,
  }) {
    final cardBg = Theme.of(context).cardColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked
              ? Colors.redAccent.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: isBlocked ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isBlocked ? Colors.redAccent : AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: avatarUrl.isValidNetworkUrl
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _buildDefaultAvatar(name, size: 68),
                            )
                          : _buildDefaultAvatar(name, size: 68),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.redAccent
                            : const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                      child: Icon(
                        isBlocked ? Icons.close_rounded : Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBlocked
                                ? Colors.redAccent.withValues(alpha: 0.12)
                                : const Color(0xFF00C853)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isBlocked
                                  ? Colors.redAccent
                                  : const Color(0xFF00C853),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? Colors.redAccent
                                      : const Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isBlocked ? 'BLOCKED' : 'ACTIVE',
                                style: TextStyle(
                                  color: isBlocked
                                      ? Colors.redAccent
                                      : const Color(0xFF00C853),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (phone.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _makePhoneCall(phone),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_rounded,
                                  size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    size: 14, color: AppColors.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Copy Phone',
                                onPressed: () =>
                                    _copyToClipboard(phone, 'Phone Number'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded,
                                size: 13, color: textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Copy Email',
                            onPressed: () =>
                                _copyToClipboard(email, 'Email Address'),
                          ),
                        ],
                      ),
                    ],
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 6),
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
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$bio"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadgePill(
                icon: Icons.sports_soccer_rounded,
                label: 'Position: $position',
                color: AppColors.primary,
                isDark: isDark,
              ),
              _buildBadgePill(
                icon: Icons.emoji_events_rounded,
                label: 'ELO: $elo',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              if (ovr > 0)
                _buildBadgePill(
                  icon: Icons.shield_rounded,
                  label: 'OVR: $ovr',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              if (skillLevel.isNotEmpty)
                _buildBadgePill(
                  icon: Icons.trending_up_rounded,
                  label: skillLevel,
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              if (preferredFoot.isNotEmpty)
                _buildBadgePill(
                  icon: Icons.directions_run_rounded,
                  label: '$preferredFoot Foot',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              if (phone.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _makePhoneCall(phone),
                    icon: const Icon(Icons.call_rounded,
                        size: 16, color: AppColors.primary),
                    label: Text(
                      'Call Player',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: isBlocked
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () =>
                            _confirmUnblock(context, playerId, name),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 17),
                        label: const Text(
                          'UNBLOCK PLAYER',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFEF4444), width: 1.5),
                          foregroundColor: const Color(0xFFEF4444),
                          backgroundColor:
                              const Color(0xFFEF4444).withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () =>
                            _showBlockModal(context, playerId, name),
                        icon: const Icon(Icons.block_rounded, size: 16),
                        label: const Text(
                          'BLOCK PLAYER',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    final totalMatches = statsMap['totalMatches'] ?? 0;
    final completedMatches = statsMap['completedMatches'] ?? 0;
    final totalPaid = statsMap['totalPaid'] ?? 0;
    final cancelledMatches = statsMap['cancelledMatches'] ?? 0;
    final totalRefunded = statsMap['totalRefunded'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Player Activity Metrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Financials & Games',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Turf participation and financial transaction summary for this player.',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardAspectRatio =
                constraints.maxWidth < 360 ? 1.4 : 1.6;

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cardAspectRatio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatMetricCard(
                  context: context,
                  isDark: isDark,
                  title: 'Matches Played',
                  value: '$totalMatches',
                  subtitle: '$completedMatches Completed',
                  icon: Icons.sports_soccer_rounded,
                  accentColor: const Color(0xFF00C853),
                  bgLight: const Color(0xFFF0FDF4),
                  bgDark: const Color(0xFF062316),
                ),
                _buildStatMetricCard(
                  context: context,
                  isDark: isDark,
                  title: 'Total Paid',
                  value: '₹$totalPaid',
                  subtitle: 'Match Entry Fees',
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF0284C7),
                  bgLight: const Color(0xFFF0F9FF),
                  bgDark: const Color(0xFF082236),
                ),
                _buildStatMetricCard(
                  context: context,
                  isDark: isDark,
                  title: 'Cancelled Matches',
                  value: '$cancelledMatches',
                  subtitle: 'Cancelled Bookings',
                  icon: Icons.cancel_outlined,
                  accentColor: const Color(0xFFEF4444),
                  bgLight: const Color(0xFFFEF2F2),
                  bgDark: const Color(0xFF2A0D12),
                ),
                _buildStatMetricCard(
                  context: context,
                  isDark: isDark,
                  title: 'Amount Refunded',
                  value: '₹$totalRefunded',
                  subtitle: 'Returned to Player',
                  icon: Icons.replay_circle_filled_rounded,
                  accentColor: const Color(0xFFD97706),
                  bgLight: const Color(0xFFFFFBEB),
                  bgDark: const Color(0xFF291B07),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatMetricCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgLight,
    required Color bgDark,
  }) {
    final cardBg = isDark ? bgDark : bgLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final labelColor = isDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.85)
        : const Color(0xFF1E293B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.block_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Block Player',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restricting access will prevent $name from joining matches and booking slots at this turf.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
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
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  void _confirmUnblock(BuildContext context, String playerId, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF00C853), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unblock Player',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to restore match and turf booking access for $name?',
          style: TextStyle(
            fontSize: 13,
            color:
                isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
}
