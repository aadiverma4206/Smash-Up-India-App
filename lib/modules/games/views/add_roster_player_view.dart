import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/game_details_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';

class AddRosterPlayerView extends StatefulWidget {
  final String targetTeam;

  const AddRosterPlayerView({
    super.key,
    required this.targetTeam,
  });

  @override
  State<AddRosterPlayerView> createState() => _AddRosterPlayerViewState();
}

class _AddRosterPlayerViewState extends State<AddRosterPlayerView> {
  late final GameDetailsController controller;
  final TextEditingController searchController = TextEditingController();
  final RxString addingUserId = ''.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GameDetailsController>();
    controller.searchPlayersForHost('');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTeamA = widget.targetTeam == 'TEAM_A';
    final teamTitle = isTeamA ? 'Team A' : 'Team B';
    final teamColor =
        isTeamA ? const Color(0xFF0284C7) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Add Player to $teamTitle',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Registered Players',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type player name, mobile number, or email address below',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field with Autofocus
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (val) => controller.searchPlayersForHost(val),
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search player name or phone...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchController,
                        builder: (context, value, child) {
                          if (value.text.isEmpty)
                            return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              searchController.clear();
                              controller.searchPlayersForHost('');
                            },
                          );
                        },
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results Body
            Expanded(
              child: Obx(() {
                if (controller.isSearchingPlayers.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Searching registered players...',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final rawResults = controller.searchPlayerResults;
                final results = rawResults.where((p) {
                  final roleId = p['roleId'] ?? p['role_id'];
                  if (roleId != null && (roleId == 1 || roleId == 2)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (results.isEmpty) {
                  final text = searchController.text.trim();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 64,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            text.isNotEmpty
                                ? 'No players found matching "$text"'
                                : 'All registered players are already in Team A or Team B roster.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text.isNotEmpty
                                ? 'Try searching with a different name or 10-digit mobile number.'
                                : 'Newly registered players will automatically appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = results[index];
                    final pId = (p['id'] ?? p['userId'] ?? '').toString();
                    final pName = (p['name'] ?? 'Player').toString();
                    final pPhone = (p['phone'] ?? '').toString();
                    final pEmail = (p['email'] ?? '').toString();
                    final pAvatar =
                        (p['profileImageUrl'] ?? p['profile_image_url'] ?? '')
                            .toString()
                            .resolvedImageUrl;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Player Profile Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: teamColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: pAvatar.isValidNetworkUrl
                                  ? CachedNetworkImage(
                                      imageUrl: pAvatar!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color:
                                            teamColor.withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            pName.isNotEmpty
                                                ? pName[0].toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              color: teamColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color:
                                            teamColor.withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            pName.isNotEmpty
                                                ? pName[0].toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              color: teamColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: teamColor.withValues(alpha: 0.15),
                                      child: Center(
                                        child: Text(
                                          pName.isNotEmpty
                                              ? pName[0].toUpperCase()
                                              : 'P',
                                          style: TextStyle(
                                            color: teamColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Player Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (pPhone.isNotEmpty) ...[
                                  Text(
                                    '📞 $pPhone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ] else if (pEmail.isNotEmpty) ...[
                                  Text(
                                    '✉️ $pEmail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Add Button
                          Obx(() {
                            final isAdding = addingUserId.value == pId;
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teamColor,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                              onPressed: isAdding
                                  ? null
                                  : () async {
                                      addingUserId.value = pId;
                                      await controller.addPlayerToTeamByHost(
                                          pId, widget.targetTeam, 'ST');
                                      addingUserId.value = '';
                                      if (mounted) Get.back();
                                    },
                              icon: isAdding
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                isAdding ? 'Adding...' : 'Add to $teamTitle',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
