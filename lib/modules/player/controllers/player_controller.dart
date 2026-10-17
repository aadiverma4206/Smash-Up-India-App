import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/player_repository.dart';
import '../../../data/models/player_profile_model.dart';
import '../../../data/models/player_stats_model.dart';
import '../../../data/models/player_dashboard_summary_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../app/theme/app_colors.dart';

class PlayerController extends GetxController {
  final PlayerRepository repository = Get.find<PlayerRepository>();

  final Rxn<PlayerProfileModel> profile = Rxn<PlayerProfileModel>();
  final Rxn<PlayerStatsModel> stats = Rxn<PlayerStatsModel>();
  final Rxn<PlayerDashboardSummaryModel> summary =
      Rxn<PlayerDashboardSummaryModel>();

  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxBool isLoadingStats = false.obs;
  final RxString errorMessage = ''.obs;

  // Navigation Index (0: Arena, 1: Explore, 2: History)
  final RxInt selectedNavIndex = 0.obs;

  // Dynamic Statistics State (4 Main Results)
  final RxList<DynamicStatCardModel> dynamicStatsList =
      <DynamicStatCardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPlayerData();
  }

  Future<void> loadPlayerData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final sum = await repository.getDashboardSummary();
      summary.value = sum;
      if (sum.profile != null) profile.value = sum.profile;
      if (sum.stats != null) {
        stats.value = sum.stats;
        _buildDynamicStatsList(sum.stats!);
      } else {
        await fetchPlayerStatistics();
      }
    } catch (e) {
      AppLogger.warning(
          'Failed to load dashboard summary: $e. Falling back...');
      try {
        final p = await repository.getProfile();
        profile.value = p;
        await fetchPlayerStatistics();
      } catch (err) {
        AppLogger.warning('Failed to load player profile/stats: $err');
        errorMessage.value = ErrorHandler.getErrorMessage(err);
      }
    } finally {
      if (profile.value == null) {
        final user = AuthService.to.currentUser.value;
        if (user != null) {
          profile.value = PlayerProfileModel(
            userId: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            city: user.city ?? 'Raipur',
            avatarUrl: user.profileImageUrl,
          );
        }
      }
      if (dynamicStatsList.isEmpty) {
        _buildDynamicStatsList(stats.value ?? PlayerStatsModel());
      }
      isLoading.value = false;
    }
  }

  /// Dedicated Backend Function: Dynamically fetch & calculate Player Statistics
  Future<void> fetchPlayerStatistics() async {
    isLoadingStats.value = true;
    try {
      final s = await repository.getStats();
      stats.value = s;
      _buildDynamicStatsList(s);
    } catch (e) {
      AppLogger.warning('Failed to load player statistics: $e');
      _buildDynamicStatsList(stats.value ?? PlayerStatsModel());
    } finally {
      isLoadingStats.value = false;
    }
  }

  void _buildDynamicStatsList(PlayerStatsModel s) {
    dynamicStatsList.value = [
      DynamicStatCardModel(
        id: 'joined',
        label: 'Joined',
        value: '${s.matchesJoined > 0 ? s.matchesJoined : s.matchesPlayed}',
        icon: Icons.sports_soccer_rounded,
        color: const Color(0xFF00C853), // Green
      ),
      DynamicStatCardModel(
        id: 'played',
        label: 'Played',
        value: '${s.matchesPlayed}',
        icon: Icons.sports_football_rounded,
        color: const Color(0xFF0288D1), // Blue
      ),
      DynamicStatCardModel(
        id: 'won',
        label: 'Won',
        value: '${s.matchesWon}',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFB300), // Amber
      ),
      DynamicStatCardModel(
        id: 'lost',
        label: 'Lost',
        value: '${s.matchesLost}',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFE53935), // Red
      ),
    ];
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? city,
    String? dateOfBirth,
    String? position,
    String? secondaryPosition,
    String? preferredFoot,
    String? skillLevel,
  }) async {
    isLoading.value = true;
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (city != null) updateData['city'] = city;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (position != null) updateData['position'] = position;
      if (secondaryPosition != null) {
        updateData['secondaryPosition'] = secondaryPosition;
      }
      if (preferredFoot != null) updateData['preferredFoot'] = preferredFoot;
      if (skillLevel != null) updateData['skillLevel'] = skillLevel;

      final updatedProfile = await repository.updateProfile(updateData);
      profile.value = updatedProfile;
      Get.back();
      ErrorHandler.showSuccessSnackBar(
        'Success',
        'Profile updated successfully!',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Update Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    isUploadingAvatar.value = true;
    try {
      final updatedProfile = await repository.uploadAvatar(filePath);
      profile.value = updatedProfile;
      ErrorHandler.showSuccessSnackBar(
        'Avatar Updated',
        'Profile image uploaded and synced to S3!',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Upload Failed', e);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<void> logout() async {
    Get.dialog(
      Builder(
        builder: (context) {
          return AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.borderColor)),
            title: Row(
              children: [
                const Icon(Icons.logout_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Confirm Logout',
                    style: TextStyle(color: context.textPrimary)),
              ],
            ),
            content: Text(
              'Are you sure you want to log out? All your local session data will be cleared.',
              style: TextStyle(color: context.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel',
                    style: TextStyle(color: context.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  Get.back();
                  await AuthService.to.logout();
                },
                child:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }
}

class DynamicStatCardModel {
  final String id;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  DynamicStatCardModel({
    required this.id,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
