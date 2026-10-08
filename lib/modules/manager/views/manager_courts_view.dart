import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_dashboard_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';

class ManagerCourtsView extends GetView<ManagerDashboardController> {
  const ManagerCourtsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Court Pitch & Slot Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (controller.courts.isNotEmpty) {
                final selectedIndex = controller.selectedCourtIndex.value;
                final courtId = controller.courts[selectedIndex].id;
                controller.fetchCourtSlots(courtId);
              } else {
                controller.loadManagerData();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const AppLoader(message: 'Loading court pitches...');
        }

        if (controller.courts.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Courts Found',
            subtitle: 'No court pitches are registered for this assigned club.',
            icon: Icons.stadium_outlined,
          );
        }

        final selectedIndex = controller.selectedCourtIndex.value.clamp(
            0, controller.courts.length - 1);
        final selectedCourt = controller.courts[selectedIndex];

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadManagerData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Selector Tabs (Court 1, Court 2, etc.)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(controller.courts.length, (index) {
                      final court = controller.courts[index];
                      final isSelected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.stadium_rounded,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          label: Text(
                            court.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          onSelected: (_) => controller.selectCourt(index),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Selected Court Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stadium_rounded,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCourt.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Surface: ${selectedCourt.surfaceType} • Status: ${selectedCourt.status}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${selectedCourt.basePricePerHour.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Court Slots Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedCourt.name} Slots Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                    ),
                    Obx(
                      () => Text(
                        '${controller.currentCourtSlots.length} Slots',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Slot List Body
                Obx(() {
                  if (controller.isSlotsLoading.value) {
                    return const AppLoader(message: 'Fetching court slots...');
                  }

                  if (controller.currentCourtSlots.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No slots scheduled for ${selectedCourt.name} today.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: controller.currentCourtSlots
                        .map((slot) => _buildSlotCard(context, slot))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlotCard(BuildContext context, Map<String, dynamic> slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String gameId = (slot['gameId'] ?? slot['id'] ?? '').toString();
    final String timeStr = (slot['time'] ??
            '${slot['startTime'] ?? slot['start_time'] ?? "18:00"} - ${slot['endTime'] ?? slot['end_time'] ?? "19:30"}')
        .toString();
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
    final String hostName =
        (slot['hostName'] ?? slot['host_name'] ?? slot['host'] ?? 'N/A')
            .toString();
    final int currentPlayers = int.tryParse(
            (slot['currentPlayers'] ?? slot['current_players_count'])
                    ?.toString() ??
                '0') ??
        0;
    final int maxPlayers = int.tryParse(
            (slot['maxPlayers'] ?? slot['max_players'])?.toString() ?? '22') ??
        22;
    final String paymentStatus =
        (slot['paymentStatus'] ?? 'PAID').toString().toUpperCase();
    final String recordingStatus =
        (slot['recordingStatus'] ?? 'AVAILABLE').toString().toUpperCase();
    final double entryFee = double.tryParse(
            (slot['entryFee'] ?? slot['entry_fee'])?.toString() ?? '0') ??
        0.0;

    Color statusColor;
    String displayStatusBadge = approvalStatus;

    if (approvalStatus == 'PENDING_APPROVAL' || approvalStatus == 'PENDING') {
      statusColor = Colors.amber;
      displayStatusBadge = 'PENDING APPROVAL';
    } else if (status == 'STARTED' || status == 'ONGOING') {
      statusColor = Colors.orange;
      displayStatusBadge = 'ONGOING';
    } else if (status == 'COMPLETED') {
      statusColor = Colors.green;
      displayStatusBadge = 'COMPLETED';
    } else if (status == 'CANCELLED' || approvalStatus == 'REJECTED') {
      statusColor = Colors.redAccent;
      displayStatusBadge = approvalStatus == 'REJECTED' ? 'REJECTED' : 'CANCELLED';
    } else {
      statusColor = AppColors.primary;
      displayStatusBadge = 'APPROVED';
    }

    final bool isPending = approvalStatus == 'PENDING_APPROVAL' || approvalStatus == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  displayStatusBadge,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            gameTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Host: $hostName • Roster: $currentPlayers / $maxPlayers Players',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Fee: ₹${entryFee.toStringAsFixed(0)} • Payment: $paymentStatus',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CCTV: $recordingStatus',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: Approve, Reject, Edit, Cancel
          if (gameId.isNotEmpty)
            Column(
              children: [
                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => controller.approvePlayerGame(gameId),
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 16),
                          label: const Text('Approve Match',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _showRejectDialog(context, gameId, gameTitle),
                          icon: const Icon(Icons.cancel_rounded,
                              color: Colors.redAccent, size: 16),
                          label: const Text('Reject Match',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showEditGameDialog(context, slot),
                        icon: const Icon(Icons.edit_rounded,
                            color: AppColors.primary, size: 16),
                        label: const Text('Edit Match Details',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    if (!isPending && status != 'CANCELLED' && status != 'COMPLETED') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        ),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.redAccent, size: 18),
                        tooltip: 'Cancel Match',
                        onPressed: () => _showCancelDialog(context, gameId, gameTitle),
                      ),
                    ],
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String gameId, String gameTitle) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Match: $gameTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter rejection reason for player host:',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Court time slot conflict',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              Get.back();
              controller.rejectPlayerGame(gameId, reason);
            },
            child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String gameId, String gameTitle) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Match: $gameTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter cancellation reason (Full refunds will be processed to joined players):',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Rain / Pitch Maintenance',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              Get.back();
              controller.cancelMatchWithRefunds(gameId, reason.isNotEmpty ? reason : 'Cancelled by club manager');
            },
            child: const Text('Cancel Match & Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditGameDialog(BuildContext context, Map<String, dynamic> slot) {
    final String gameId = (slot['gameId'] ?? slot['id'] ?? '').toString();
    final titleController = TextEditingController(text: (slot['gameTitle'] ?? slot['title'] ?? '').toString());
    final entryFeeController = TextEditingController(text: (slot['entryFee'] ?? slot['entry_fee'] ?? '200').toString());
    final maxPlayersController = TextEditingController(text: (slot['maxPlayers'] ?? slot['max_players'] ?? '22').toString());

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Match Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Match Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: entryFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Entry Fee per Player (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxPlayersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Capacity Players',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newTitle = titleController.text.trim();
              final fee = double.tryParse(entryFeeController.text.trim()) ?? 0.0;
              final players = int.tryParse(maxPlayersController.text.trim()) ?? 22;

              Get.back();
              controller.updateGame(gameId, {
                if (newTitle.isNotEmpty) 'title': newTitle,
                'entryFee': fee,
                'maxPlayers': players,
              });
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
