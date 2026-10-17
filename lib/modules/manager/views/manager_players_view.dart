import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/errors/error_handler.dart';

class ManagerPlayersView extends StatefulWidget {
  const ManagerPlayersView({super.key});

  @override
  State<ManagerPlayersView> createState() => _ManagerPlayersViewState();
}

class _ManagerPlayersViewState extends State<ManagerPlayersView> {
  late final ManagerDashboardController controller;
  final TextEditingController searchController = TextEditingController();
  final RxString selectedStatus = 'ACTIVE'.obs;
  final RxString selectedPosition = 'ALL'.obs;
  final RxString selectedSort =
      'NAME_ASC'.obs; // NAME_ASC, ELO_DESC, MATCHES_DESC

  @override
  void initState() {
    super.initState();
    controller = Get.find<ManagerDashboardController>();
    controller.fetchAllPlayers(status: 'ACTIVE');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    controller.fetchAllPlayers(
      search: query.trim().isEmpty ? null : query.trim(),
      status: selectedStatus.value,
    );
  }

  void _onStatusFilter(String status) {
    selectedStatus.value = status;
    controller.fetchAllPlayers(
      search: searchController.text.trim().isEmpty
          ? null
          : searchController.text.trim(),
      status: status,
    );
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

  List<Map<String, dynamic>> _applyFiltersAndSorting(
      List<Map<String, dynamic>> players) {
    var list = List<Map<String, dynamic>>.from(players);

    // Filter by position if not ALL
    if (selectedPosition.value != 'ALL') {
      final pos = selectedPosition.value.toUpperCase();
      list = list.where((p) {
        final playerPos = (p['position'] ?? '').toString().toUpperCase();
        return playerPos.contains(pos);
      }).toList();
    }

    // Sort
    if (selectedSort.value == 'NAME_ASC') {
      list.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
    } else if (selectedSort.value == 'ELO_DESC') {
      list.sort((a, b) {
        final eloA = int.tryParse(
                a['elo_rating']?.toString() ?? a['elo']?.toString() ?? '750') ??
            750;
        final eloB = int.tryParse(
                b['elo_rating']?.toString() ?? b['elo']?.toString() ?? '750') ??
            750;
        return eloB.compareTo(eloA);
      });
    } else if (selectedSort.value == 'MATCHES_DESC') {
      list.sort((a, b) {
        final matchesA =
            int.tryParse(a['matches_played']?.toString() ?? '0') ?? 0;
        final matchesB =
            int.tryParse(b['matches_played']?.toString() ?? '0') ?? 0;
        return matchesB.compareTo(matchesA);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Player Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh Directory',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchAllPlayers(
              search: searchController.text.trim().isEmpty
                  ? null
                  : searchController.text.trim(),
              status: selectedStatus.value,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 🌟 Search & Filter Section
            Container(
              color: isDark ? AppColors.darkCard : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or position...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 22),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkInputBg
                          : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Status Chips & Sort Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Filters
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['ACTIVE', 'BLOCKED'].map((status) {
                              return Obx(() {
                                final isSelected =
                                    selectedStatus.value == status;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: InkWell(
                                    onTap: () => _onStatusFilter(status),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark
                                                ? AppColors.darkInputBg
                                                : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.darkBorder
                                                  : const Color(0xFFE2E8F0)),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : const Color(0xFF334155)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort dropdown menu
                      Obx(() {
                        return PopupMenuButton<String>(
                          initialValue: selectedSort.value,
                          tooltip: 'Sort Players',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Theme.of(context).cardColor,
                          onSelected: (val) => selectedSort.value = val,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'NAME_ASC',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha_rounded,
                                      size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Name (A - Z)',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'ELO_DESC',
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events_rounded,
                                      size: 16, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 8),
                                  Text('Highest ELO',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'MATCHES_DESC',
                              child: Row(
                                children: [
                                  Icon(Icons.sports_soccer_rounded,
                                      size: 16, color: Color(0xFF00C853)),
                                  SizedBox(width: 8),
                                  Text('Most Matches',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkInputBg
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sort_rounded,
                                    size: 15,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  _getSortLabel(selectedSort.value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. 👥 Player List Body
            Expanded(
              child: Obx(() {
                final bool isBusy = controller.isPlayersLoading.value ||
                    (controller.isActionLoading.value &&
                        controller.playersList.isEmpty);

                if (isBusy && controller.playersList.isEmpty) {
                  return const AppLoader(
                      message: 'Fetching player directory...');
                }

                final filteredPlayers =
                    _applyFiltersAndSorting(controller.playersList);

                if (filteredPlayers.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => controller.fetchAllPlayers(
                    search: searchController.text.trim().isEmpty
                        ? null
                        : searchController.text.trim(),
                    status: selectedStatus.value == 'ALL'
                        ? null
                        : selectedStatus.value,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: filteredPlayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      return _buildPlayerCard(context, isDark, player);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sort) {
    if (sort == 'ELO_DESC') return 'Top ELO';
    if (sort == 'MATCHES_DESC') return 'Matches';
    return 'Name A-Z';
  }

  Widget _buildPlayerCard(
      BuildContext context, bool isDark, Map<String, dynamic> player) {
    final cardBg = Theme.of(context).cardColor;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    final String playerId = (player['id'] ?? player['userId'] ?? '').toString();
    final String name = (player['name'] ?? 'Player').toString();
    final String phone =
        (player['phone'] ?? player['email'] ?? 'No Phone').toString();
    final bool isBlocked =
        (player['status']?.toString().toUpperCase() == 'BLOCKED') ||
            (player['status']?.toString().toUpperCase() == 'SUSPENDED') ||
            (player['isBlocked'] == true);
    final String? avatarUrl = player['profile_image_url']?.toString() ??
        player['avatarUrl']?.toString() ??
        player['profileImageUrl']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? Colors.redAccent.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: isBlocked ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(
            Routes.managerPlayerDetail,
            arguments: {'playerId': playerId, 'player': player},
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 1. WhatsApp-Style Circle Avatar with status ring
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: avatarUrl.isValidNetworkUrl
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _defaultAvatar(name, size: 50),
                            )
                          : _defaultAvatar(name, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.redAccent
                              : const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // 2. Name & Mobile Number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _makePhoneCall(phone),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Status Badge & Quick Action Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.redAccent.withValues(alpha: 0.12)
                            : const Color(0xFF00C853).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.redAccent
                              : const Color(0xFF00C853),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isBlocked ? 'BLOCKED' : 'ACTIVE',
                        style: TextStyle(
                          color: isBlocked
                              ? Colors.redAccent
                              : const Color(0xFF00C853),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isBlocked) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _confirmUnblock(context, playerId, name),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: Colors.green),
                        label: const Text('Unblock',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _makePhoneCall(phone),
                            icon: const Icon(Icons.phone_outlined,
                                size: 13, color: AppColors.primary),
                            label: const Text('Call',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                _showBlockModal(context, playerId, name),
                            icon: const Icon(Icons.block_rounded,
                                size: 13, color: Colors.redAccent),
                            label: const Text('Block',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name, {double size = 44}) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final hasSearch = searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No Matching Players' : 'No Players Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'No players matched your query "${searchController.text.trim()}".'
                  : 'No player accounts currently registered under this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
              ),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
              ),
            ],
          ],
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
                'Block Player: $name',
                style: TextStyle(
                  fontSize: 16,
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
              'Restricting player access will prevent them from joining matches or booking slots at this turf.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Enter reason for restriction...',
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
            child: const Text('Confirm Block',
                style: TextStyle(fontWeight: FontWeight.w800)),
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
                'Unblock Player: $name',
                style: TextStyle(
                  fontSize: 16,
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
            child: const Text('Confirm Unblock',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
