import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../controllers/manager_games_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/game_model.dart';
import '../../../core/utils/app_date_utils.dart';

class ManagerCourtsView extends GetView<ManagerDashboardController> {
  const ManagerCourtsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController =
        TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          if (controller.courts.isEmpty) {
            return const Text('Court Matches');
          }
          final selectedIndex = controller.selectedCourtIndex.value
              .clamp(0, controller.courts.length - 1);
          final courtName = controller.courts[selectedIndex].name;
          return Text('$courtName Matches',
              style: const TextStyle(fontWeight: FontWeight.bold));
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (controller.courts.isNotEmpty) {
                final selectedIndex = controller.selectedCourtIndex.value;
                final courtId = controller.courts[selectedIndex].id;
                controller.fetchCourtSlots(courtId,
                    courtIndex: selectedIndex + 1);
              } else {
                controller.loadManagerData();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SkeletonContainer(
                    width: double.infinity, height: 48, borderRadius: 12),
                SizedBox(height: 16),
                Row(
                  children: [
                    SkeletonContainer(width: 80, height: 32, borderRadius: 8),
                    SizedBox(width: 8),
                    SkeletonContainer(width: 80, height: 32, borderRadius: 8),
                    SizedBox(width: 8),
                    SkeletonContainer(width: 80, height: 32, borderRadius: 8),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(child: SkeletonListLoader(count: 4)),
              ],
            ),
          );
        }

        if (controller.courts.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Courts Found',
            subtitle: 'No court pitches are registered for this assigned club.',
            icon: Icons.stadium_outlined,
          );
        }

        final selectedIndex = controller.selectedCourtIndex.value
            .clamp(0, controller.courts.length - 1);
        final selectedCourt = controller.courts[selectedIndex];
        final matchesList = controller.filteredCourtSlots;

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadManagerData();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (val) => controller.searchQuery.value = val,
                      style: TextStyle(
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by player name, time, status...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon:
                            Obx(() => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        size: 18,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                    onPressed: () {
                                      searchController.clear();
                                      controller.searchQuery.value = '';
                                    },
                                  )
                                : const SizedBox.shrink()),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
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
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateChip(context, 'ALL', 'All Dates',
                              Icons.calendar_today_rounded),
                          _buildDateChip(
                              context, 'TODAY', 'Today', Icons.today_rounded),
                          _buildDateChip(context, 'TOMORROW', 'Tomorrow',
                              Icons.upcoming_rounded),
                          _buildDateChip(context, 'CUSTOM', 'Select Date',
                              Icons.date_range_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Matches (${matchesList.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.isSlotsLoading.value
                    ? const SkeletonListLoader(count: 4)
                    : matchesList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No games scheduled on ${selectedCourt.name} matching your filter.',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: matchesList.length,
                              itemBuilder: (context, index) {
                                final slot = matchesList[index];
                                return _buildMatchCard(
                                    context, slot, selectedCourt.name);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMatchCard(
      BuildContext context, Map<String, dynamic> slot, String courtName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String gameId = (slot['gameId'] ?? slot['id'] ?? '').toString();

    String startTime =
        (slot['startTime'] ?? slot['start_time'] ?? '18:30').toString();
    if (startTime.length > 5) {
      startTime = startTime.substring(0, 5);
    }

    final String format = (slot['format'] ?? '1v1').toString().toUpperCase();
    final String privacy =
        (slot['privacy'] ?? 'PUBLIC').toString().toUpperCase();
    final String approvalStatus = (slot['approvalStatus'] ??
            slot['approval_status'] ??
            slot['status'] ??
            'APPROVED')
        .toString()
        .toUpperCase();
    final String status =
        (slot['status'] ?? 'SCHEDULED').toString().toUpperCase();
    final String gameTitle =
        (slot['gameTitle'] ?? slot['title'] ?? 'Court Match').toString();
    final String hostName = (slot['hostName'] ??
            slot['host_name'] ??
            slot['host'] ??
            'Player Singh')
        .toString();
    final int currentPlayers = int.tryParse(
            (slot['currentPlayers'] ?? slot['current_players_count'])
                    ?.toString() ??
                '1') ??
        1;
    final int maxPlayers = int.tryParse(
            (slot['maxPlayers'] ?? slot['max_players'])?.toString() ?? '2') ??
        2;
    final double entryFee = double.tryParse(
            (slot['entryFee'] ?? slot['entry_fee'])?.toString() ?? '100') ??
        100.0;

    final String matchDateRaw =
        (slot['matchDate'] ?? slot['match_date'] ?? '').toString();
    final String formattedDate =
        AppDateUtils.formatDate(matchDateRaw, format: 'EEE, dd MMM');

    Color statusColor;
    String displayStatusBadge = approvalStatus;

    final bool isPending =
        approvalStatus.contains('PENDING') || status.contains('PENDING');

    if (isPending) {
      statusColor = Colors.amber;
      displayStatusBadge = 'PENDING';
    } else if (status == 'STARTED' || status == 'ONGOING') {
      statusColor = Colors.orange;
      displayStatusBadge = 'ONGOING';
    } else if (status == 'COMPLETED') {
      statusColor = Colors.green;
      displayStatusBadge = 'COMPLETED';
    } else if (status == 'CANCELLED' || approvalStatus == 'REJECTED') {
      statusColor = Colors.redAccent;
      displayStatusBadge =
          approvalStatus == 'REJECTED' ? 'REJECTED' : 'CANCELLED';
    } else {
      statusColor = AppColors.primary;
      displayStatusBadge = 'APPROVED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _openGameDetails(gameId, slot, courtName, format, privacy, status,
              approvalStatus, gameTitle, currentPlayers, maxPlayers, entryFee);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          startTime,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group_rounded,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$currentPlayers/$maxPlayers Slots',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade700,
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
            Container(
              width: 1,
              height: 72,
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(format,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(privacy,
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(displayStatusBadge,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        child: Text(
                          hostName.isNotEmpty ? hostName[0].toUpperCase() : 'P',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: hostName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: ' • All Stars Arena Turf',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee_rounded,
                              size: 14, color: Colors.green),
                          Text(
                            entryFee.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          const Text('Fee',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPending) ...[
                            InkWell(
                              onTap: () => controller.approvePlayerGame(gameId),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  _showRejectDialog(context, gameId, gameTitle),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  border: Border.all(color: Colors.redAccent),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.redAccent, size: 15),
                              ),
                            ),
                          ] else ...[
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey, size: 20),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGameDetails(
    String gameId,
    Map<String, dynamic> slot,
    String courtName,
    String format,
    String privacy,
    String status,
    String approvalStatus,
    String gameTitle,
    int currentPlayers,
    int maxPlayers,
    double entryFee,
  ) {
    if (gameId.isNotEmpty) {
      if (Get.isRegistered<ManagerGamesController>()) {
        final gamesCtrl = Get.find<ManagerGamesController>();
        gamesCtrl.selectedGame.value = GameModel(
          id: gameId,
          title: gameTitle,
          clubId: 'all_stars_arena_club',
          clubName: 'All Stars Arena Turf',
          courtId: slot['court_id'] ?? slot['courtId'] ?? 'court_1',
          courtName: courtName,
          matchDate: slot['match_date'] ?? DateTime.now().toIso8601String(),
          startTime: slot['startTime'] ?? slot['start_time'] ?? '18:30',
          endTime: slot['endTime'] ?? slot['end_time'] ?? '20:00',
          status: status,
          format: format,
          perPlayerFee: entryFee,
          maxPlayers: maxPlayers,
          currentPlayers: currentPlayers,
          skillRequirement: 'ALL',
          privacy: privacy,
          createdByPlayer: false,
          teamAScore:
              int.tryParse(slot['team_a_score']?.toString() ?? '0') ?? 0,
          teamBScore:
              int.tryParse(slot['team_b_score']?.toString() ?? '0') ?? 0,
        );
      }
      Get.toNamed('/manager/games/details');
    }
  }

  void _showRejectDialog(
      BuildContext context, String gameId, String gameTitle) {
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
                  child: const Icon(Icons.cancel_outlined,
                      color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reject Match: $gameTitle',
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
              'Enter rejection reason for player host:',
              style: TextStyle(
                fontSize: 12.5,
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Court time slot conflict',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade400,
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkInputBg : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0)),
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
                              : const Color(0xFFE2E8F0)),
                    ),
                    onPressed: () => Get.back(),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final reason = reasonController.text.trim();
                      Get.back();
                      controller.rejectPlayerGame(gameId, reason);
                    },
                    child: const Text('Confirm Reject',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(
      BuildContext context, String key, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final currentFilter = controller.selectedDateFilter.value;
      final isSelected = currentFilter == key ||
          (key == 'CUSTOM' &&
              !['ALL', 'TODAY', 'TOMORROW'].contains(currentFilter));

      String displayLabel = label;
      if (key == 'CUSTOM') {
        if (controller.customSelectedDate.value != null) {
          displayLabel = controller.customSelectedDate.value!
              .toIso8601String()
              .split('T')[0];
        } else {
          displayLabel = 'Select Date';
        }
      }

      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ChoiceChip(
          avatar: Icon(
            icon,
            size: 14,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.primary),
          ),
          label: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : Colors.black87),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
          ),
          onSelected: (_) => controller.changeDateFilter(key),
        ),
      );
    });
  }
}
