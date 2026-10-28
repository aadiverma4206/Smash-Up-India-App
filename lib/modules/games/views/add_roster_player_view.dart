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
  final RxSet<String> addedUserIds = <String>{}.obs;

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

  Set<String> _getExistingRosterIds() {
    final set = <String>{};
    if (controller.game.value?.roster != null) {
      for (final r in controller.game.value!.roster!) {
        if (r.userId.isNotEmpty) set.add(r.userId);
      }
    }
    for (final r in controller.teamARoster) {
      if (r.userId.isNotEmpty) set.add(r.userId);
    }
    for (final r in controller.teamBRoster) {
      if (r.userId.isNotEmpty) set.add(r.userId);
    }
    return set;
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
        actions: [
          Obx(() {
            if (addedUserIds.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'Done (${addedUserIds.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Search Header Card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search Registered Players',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                          ),
                          Obx(() {
                            if (addedUserIds.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: teamColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${addedUserIds.length} Added',
                                style: TextStyle(
                                  color: teamColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                        ],
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

                      // Search Input Box
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: (val) =>
                            controller.searchPlayersForHost(val),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
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
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
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

                // Search Results
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
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final existingRoster = _getExistingRosterIds();
                    final rawResults = controller.searchPlayerResults;

                    final results = rawResults.where((p) {
                      final pId = (p['id'] ?? p['userId'] ?? p['user_id'] ?? '')
                          .toString();
                      final roleId = p['roleId'] ?? p['role_id'];

                      // Exclude Admins & Managers
                      if (roleId != null && (roleId == 1 || roleId == 2)) {
                        return false;
                      }

                      // Exclude players already in the match or added during this session
                      if (pId.isNotEmpty &&
                          (existingRoster.contains(pId) ||
                              addedUserIds.contains(pId))) {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (results.isEmpty) {
                      final text = searchController.text.trim();
                      final hasAddedAny = addedUserIds.isNotEmpty;

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasAddedAny
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.person_search_rounded,
                                size: 60,
                                color: hasAddedAny
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                text.isNotEmpty
                                    ? 'No remaining players found matching "$text"'
                                    : (hasAddedAny
                                        ? 'All matching players added!'
                                        : 'All registered players are already in Team A or Team B roster.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                text.isNotEmpty
                                    ? 'Try searching with another name or mobile number.'
                                    : (hasAddedAny
                                        ? 'Tap "Done" at top right to return to match details.'
                                        : 'Newly registered players will automatically appear here.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (hasAddedAny) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 11),
                                  ),
                                  onPressed: () => Get.back(),
                                  icon:
                                      const Icon(Icons.check_rounded, size: 18),
                                  label: Text(
                                    'Done (${addedUserIds.length} Added)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        if (isWide) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisExtent: 84,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              return _buildPlayerCard(
                                context,
                                results[index],
                                teamColor,
                                teamTitle,
                                isDark,
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildPlayerCard(
                              context,
                              results[index],
                              teamColor,
                              teamTitle,
                              isDark,
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    Map<String, dynamic> p,
    Color teamColor,
    String teamTitle,
    bool isDark,
  ) {
    final pId = (p['id'] ?? p['userId'] ?? p['user_id'] ?? '').toString();
    final pName = (p['name'] ?? 'Player').toString();
    final pPhone = (p['phone'] ?? '').toString();
    final pEmail = (p['email'] ?? '').toString();
    final pAvatar = (p['profileImageUrl'] ?? p['profile_image_url'] ?? '')
        .toString()
        .resolvedImageUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      child: Row(
        children: [
          // Profile Avatar
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
                        color: teamColor.withValues(alpha: 0.15),
                        child: Center(
                          child: Text(
                            pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: teamColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: teamColor.withValues(alpha: 0.15),
                        child: Center(
                          child: Text(
                            pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
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
                          pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
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
          const SizedBox(width: 12),

          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                if (pPhone.isNotEmpty) ...[
                  Text(
                    '📞 $pPhone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 8),

          // Add Button with Animated Loading State
          Obx(() {
            final isAddingThisPlayer = addingUserId.value == pId;
            final isAnyAdding = addingUserId.value.isNotEmpty;

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teamColor,
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                disabledBackgroundColor: teamColor.withValues(alpha: 0.5),
              ),
              onPressed: (isAnyAdding)
                  ? null
                  : () async {
                      addingUserId.value = pId;
                      await controller.addPlayerToTeamByHost(
                          pId, widget.targetTeam, 'ST');
                      addedUserIds.add(pId);
                      addingUserId.value = '';
                    },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isAddingThisPlayer
                    ? Row(
                        key: const ValueKey('adding_loader'),
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Adding...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('add_button'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Add to $teamTitle',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
