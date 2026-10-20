import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/match_history_controller.dart';
import '../../../data/models/game_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/app_date_utils.dart';

class MatchHistoryView extends StatefulWidget {
  final bool showBackButton;

  const MatchHistoryView({super.key, this.showBackButton = false});

  @override
  State<MatchHistoryView> createState() => _MatchHistoryViewState();
}

class _MatchHistoryViewState extends State<MatchHistoryView> {
  late final MatchHistoryController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MatchHistoryController>()) {
      controller = Get.find<MatchHistoryController>();
    } else {
      controller = Get.put(MatchHistoryController());
    }
  }

  Map<String, List<GameModel>> _groupGamesByDate(List<GameModel> gamesList) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final pastGames = gamesList.where((g) {
      final matchDt = AppDateUtils.parseDate(g.matchDate) ??
          AppDateUtils.parseMatchDateTime(g.matchDate, g.startTime);
      if (matchDt == null) return true;
      return !matchDt.isAfter(todayEnd);
    }).toList();

    final sortedGames = List<GameModel>.from(pastGames);
    sortedGames.sort((a, b) {
      final dtA = AppDateUtils.parseMatchDateTime(a.matchDate, a.startTime) ??
          AppDateUtils.parseDate(a.matchDate) ??
          DateTime(2000);
      final dtB = AppDateUtils.parseMatchDateTime(b.matchDate, b.startTime) ??
          AppDateUtils.parseDate(b.matchDate) ??
          DateTime(2000);
      return dtB.compareTo(dtA);
    });

    final Map<String, List<GameModel>> grouped = {};
    final todayIso = AppDateUtils.formatIsoDate(now);
    final yesterdayIso =
        AppDateUtils.formatIsoDate(now.subtract(const Duration(days: 1)));

    for (final game in sortedGames) {
      final matchDt = AppDateUtils.parseDate(game.matchDate) ??
          AppDateUtils.parseMatchDateTime(game.matchDate, game.startTime) ??
          now;
      final rawDateIso = AppDateUtils.formatIsoDate(matchDt);

      String headerKey;
      if (rawDateIso == todayIso) {
        headerKey =
            'TODAY • ${AppDateUtils.formatDate(matchDt, format: "dd MMM yyyy")}';
      } else if (rawDateIso == yesterdayIso) {
        headerKey =
            'YESTERDAY • ${AppDateUtils.formatDate(matchDt, format: "dd MMM yyyy")}';
      } else {
        headerKey =
            AppDateUtils.formatDate(matchDt, format: "EEE, dd MMM yyyy");
      }

      grouped.putIfAbsent(headerKey, () => []).add(game);
    }

    return grouped;
  }

  Widget _buildDateHeader(BuildContext context, String headerTitle, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String displayTitle = headerTitle.replaceAll(' • ', ', ');
    if (displayTitle.startsWith('TODAY')) {
      displayTitle = displayTitle.replaceFirst('TODAY', 'Today');
    } else if (displayTitle.startsWith('YESTERDAY')) {
      displayTitle = displayTitle.replaceFirst('YESTERDAY', 'Yesterday');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 8),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                width: 0.8,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? 'Match' : 'Matches'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search completed or cancelled matches...',
              hintStyle: TextStyle(
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon:
                  const Icon(Icons.history_rounded, color: AppColors.primary),
              suffixIcon: controller.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () {
                        controller.searchController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['COMPLETED', 'CANCELLED'].map((filter) {
                return Obx(() {
                  final isSelected = controller.activeFilter.value == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                              : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      onSelected: (_) {
                        controller.activeFilter.value = filter;
                        controller.fetchHistory(isRefresh: true);
                      },
                    ),
                  );
                });
              }).toList(),
            ),
          ),
          Obx(() {
            if (!controller.isOfflineMode.value) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'Offline Mode • Showing 3-day SQLite local history',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Get.back(),
                )
              : null,
          title: const Text('Match History & Records',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => controller.fetchHistory(isRefresh: true),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            final displayList = controller.filteredHistoryGames;

            final List<dynamic> flattenedItems = [
              'SEARCH_HEADER',
            ];

            if (controller.isSearchingOrFiltering.value ||
                (controller.isLoadingMore.value &&
                    controller.historyGames.isEmpty)) {
              flattenedItems.addAll([
                'SKELETON_CARD',
                'SKELETON_CARD',
                'SKELETON_CARD',
                'SKELETON_CARD',
              ]);
            } else if (displayList.isEmpty) {
              flattenedItems.add('EMPTY_STATE');
            } else {
              final groupedMap = _groupGamesByDate(displayList);
              for (final entry in groupedMap.entries) {
                flattenedItems
                    .add({'header': entry.key, 'count': entry.value.length});
                flattenedItems.addAll(entry.value);
              }
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchHistory(isRefresh: true),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  controller: controller.scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: flattenedItems.length +
                      (controller.hasMore.value &&
                              !controller.isSearchingOrFiltering.value
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == flattenedItems.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final item = flattenedItems[index];

                    if (item == 'SEARCH_HEADER') {
                      return _buildSearchAndFiltersHeader(context);
                    } else if (item == 'SKELETON_CARD') {
                      return const SkeletonMatchCard();
                    } else if (item == 'EMPTY_STATE') {
                      return const EmptyStateWidget(
                        title: 'No Match History',
                        subtitle:
                            'You have not completed or joined any matches yet.',
                        icon: Icons.history_rounded,
                      );
                    } else if (item is Map<String, dynamic>) {
                      return _buildDateHeader(
                        context,
                        item['header'] as String,
                        item['count'] as int,
                      );
                    } else if (item is GameModel) {
                      return _buildHistoryCard(context, item);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusUpper = game.status.toUpperCase();
    final isCompleted = statusUpper == 'COMPLETED' || statusUpper == 'FINISHED';

    String startTime =
        AppDateUtils.formatTime(game.startTime, format: 'h:mm a');
    if (startTime.isEmpty) {
      startTime = game.startTime;
      if (startTime.length > 5) startTime = startTime.substring(0, 5);
    }

    final matchDt = AppDateUtils.parseDate(game.matchDate) ??
        AppDateUtils.parseMatchDateTime(game.matchDate, game.startTime);
    final String formattedDate = matchDt != null
        ? AppDateUtils.formatDate(matchDt, format: 'EEE, dd MMM')
        : (game.matchDate.contains('T')
            ? game.matchDate.split('T')[0]
            : game.matchDate);

    final double fee = game.perPlayerFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.redAccent.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            controller.selectedGame.value = game;
            controller.fetchMatchRecording(game.id);
            Get.toNamed(Routes.playerHistoryDetails);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14,
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.redAccent),
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
                              '${game.currentPlayers}/${game.maxPlayers} Slots',
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
                            child: Text(game.format,
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
                            child: Text(game.privacy,
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isCompleted
                                      ? Colors.green
                                      : Colors.redAccent)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(game.status.toUpperCase(),
                                style: TextStyle(
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.redAccent,
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
                            backgroundColor:
                                (isCompleted ? Colors.green : Colors.redAccent)
                                    .withValues(alpha: 0.2),
                            child: Text(
                              game.title.isNotEmpty
                                  ? game.title[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                  color: isCompleted
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${game.title} • ${game.courtName}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.black87),
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
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Score: A ${game.teamAScore} - ${game.teamBScore} B',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            )
                          else
                            const Text('Cancelled',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee_rounded,
                                  size: 13, color: Colors.green),
                              Text(
                                fee.toStringAsFixed(0),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              const SizedBox(width: 2),
                              const Text('Fee',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
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
        ),
      ),
    );
  }
}
