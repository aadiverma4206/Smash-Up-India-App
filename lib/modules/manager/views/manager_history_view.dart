import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manager_games_controller.dart';
import '../repositories/manager_repository.dart';
import '../../../data/models/game_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/app_logger.dart';

class ManagerHistoryView extends StatefulWidget {
  const ManagerHistoryView({super.key});

  @override
  State<ManagerHistoryView> createState() => _ManagerHistoryViewState();
}

class _ManagerHistoryViewState extends State<ManagerHistoryView> {
  late final ManagerRepository repository;
  late final ManagerGamesController gamesController;
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  final RxList<GameModel> historyGames = <GameModel>[].obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString activeFilter = 'ALL'.obs; // ALL, COMPLETED, CANCELLED
  int currentOffset = 0;
  final int limit = 20;

  @override
  void initState() {
    super.initState();
    repository = Get.find<ManagerRepository>();
    if (Get.isRegistered<ManagerGamesController>()) {
      gamesController = Get.find<ManagerGamesController>();
    } else {
      gamesController = Get.put(ManagerGamesController());
    }
    fetchHistory(isRefresh: true);
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        fetchHistory(isRefresh: false);
      }
    }
  }

  Future<void> fetchHistory({required bool isRefresh}) async {
    if (isRefresh) {
      currentOffset = 0;
      hasMore.value = true;
    }
    if (!hasMore.value && !isRefresh) return;

    isLoadingMore.value = true;

    try {
      final list = await repository.getClubHistory(
        limit: limit,
        offset: currentOffset,
        status: activeFilter.value,
      );
      if (list.length < limit) {
        hasMore.value = false;
      }
      if (isRefresh) {
        historyGames.assignAll(list);
      } else {
        historyGames.addAll(list);
      }
      currentOffset += list.length;
    } catch (e) {
      AppLogger.warning('Error fetching history: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  List<GameModel> get filteredHistoryGames {
    final query = searchController.text.trim().toLowerCase();
    return historyGames.where((game) {
      if (query.isNotEmpty) {
        final title = game.title.toLowerCase();
        final court = game.courtName.toLowerCase();
        final format = game.format.toLowerCase();
        if (!title.contains(query) && !court.contains(query) && !format.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Match History & Records',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fetchHistory(isRefresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search completed or cancelled matches...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.history_rounded, color: AppColors.primary),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips (ALL, COMPLETED, CANCELLED)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'COMPLETED', 'CANCELLED'].map((filter) {
                        return Obx(() {
                          final isSelected = activeFilter.value == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.textPrimaryDark : Colors.black87),
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
                                      : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              onSelected: (_) {
                                activeFilter.value = filter;
                                fetchHistory(isRefresh: true);
                              },
                            ),
                          );
                        });
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // History Count Header
                  Obx(() => Text(
                        'History Records (${filteredHistoryGames.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                        ),
                      )),
                ],
              ),
            ),

            // History List Body with Scrollbar & Infinite Scroll Pagination
            Expanded(
              child: Obx(() {
                if (isLoadingMore.value && historyGames.isEmpty) {
                  return const AppLoader(message: 'Loading match history records...');
                }

                final displayList = filteredHistoryGames;

                if (displayList.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Match History',
                    subtitle: 'No completed or cancelled matches recorded yet.',
                    icon: Icons.history_rounded,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => fetchHistory(isRefresh: true),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayList.length + (hasMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayList.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final game = displayList[index];
                        return _buildHistoryCard(context, game);
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, GameModel game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = game.status.toUpperCase() == 'COMPLETED';

    String startTime = game.startTime;
    if (startTime.length > 5) startTime = startTime.substring(0, 5);

    String formattedDate = 'Thu, 08 Oct';
    try {
      final parsedDate = DateTime.parse(game.matchDate);
      formattedDate = AppDateUtils.formatDate(parsedDate, format: 'EEE, dd MMM');
    } catch (_) {
      formattedDate = game.matchDate.split('T')[0];
    }

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
            gamesController.selectedGame.value = game;
            Get.toNamed('/manager/games/details');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Time, Date & Slots
                SizedBox(
                  width: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: isCompleted ? Colors.green : Colors.redAccent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              startTime,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
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
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, size: 13, color: Colors.green),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${game.currentPlayers}/${game.maxPlayers} Slots',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
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
                // Vertical Divider
                Container(
                  width: 1,
                  height: 72,
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                ),
                const SizedBox(width: 12),
                // Right Column: Badges, Title/Court, Score, Fee
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top row: Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(game.format, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(game.privacy, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isCompleted ? Colors.green : Colors.redAccent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(game.status.toUpperCase(), style: TextStyle(color: isCompleted ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Title & Court row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: (isCompleted ? Colors.green : Colors.redAccent).withValues(alpha: 0.2),
                            child: Text(
                              game.title.isNotEmpty ? game.title[0].toUpperCase() : 'M',
                              style: TextStyle(color: isCompleted ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${game.title} • ${game.courtName}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Score & Fee row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Score: A ${game.teamAScore} - ${game.teamBScore} B',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            )
                          else
                            const Text('Cancelled', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),

                          Row(
                            children: [
                              const Icon(Icons.currency_rupee_rounded, size: 13, color: Colors.green),
                              Text(
                                game.perPlayerFee.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(width: 2),
                              const Text('Fee', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
