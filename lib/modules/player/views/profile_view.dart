import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/player_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/widgets/app_loader.dart';
import '../../support/widgets/support_legal_cards.dart';

class ProfileView extends GetView<PlayerController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Player Passport',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            tooltip: 'Edit Profile',
            onPressed: () => Get.toNamed('/player/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: controller.loadPlayerData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const AppLoader(message: 'Loading Player Passport...');
        }

        final p = controller.profile.value;

        if (p == null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No player profile data found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.loadPlayerData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Loading'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadPlayerData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Player Card Header
                _buildHeroHeader(context, p),
                const SizedBox(height: 20),

                // 2. Personal Attributes Card
                _buildSectionHeader(
                    context, 'Player Attributes', Icons.badge_outlined),
                const SizedBox(height: 10),
                _buildAttributesCard(context, p),
                const SizedBox(height: 20),

                // 4. Preferences & Storage Management
                _buildSectionHeader(
                    context, 'Preferences & Theme', Icons.tune_rounded),
                const SizedBox(height: 10),
                _buildPreferencesAndStorageCard(context),
                const SizedBox(height: 20),

                // 6. Help & Support and Legal Section
                const SupportAndLegalSection(),
                const SizedBox(height: 24),

                // 7. Prominent Logout Action Button
                _buildLogoutCard(context),
                const SizedBox(height: 32),

                // App Footer
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'ALL STARS ARENA • v1.0.0',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'LIVE. PLAY. CONNECT.',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Hero Player Banner
  Widget _buildHeroHeader(BuildContext context, dynamic p) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.secondary, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/player/profile/edit'),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Name, Email, Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.verified,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.email,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadgeChip(p.position, AppColors.primary),
                          _buildBadgeChip(
                              '${p.preferredFoot} FOOT', Colors.blueGrey),
                          _buildBadgeChip(p.skillLevel, AppColors.secondary,
                              textColor: Colors.black),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // OVR Rating
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OVR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${p.ovr}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String label, Color color,
      {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// 3. Attributes List Card
  Widget _buildAttributesCard(BuildContext context, dynamic p) {
    return Card(
      child: Column(
        children: [
          _buildInfoRow(
              context, 'Home City', p.city, Icons.location_city_rounded),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoRow(context, 'Preferred Foot', p.preferredFoot,
              Icons.sports_football),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoRow(
              context, 'Pitch Position', p.position, Icons.stadium_rounded),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoRow(context, 'Player Bio', p.bio ?? 'No bio set yet',
              Icons.notes_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : Colors.black87,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Preferences & Cache Management Card
  Widget _buildPreferencesAndStorageCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Obx(() {
            final currentMode = Get.isRegistered<ThemeService>()
                ? ThemeService.to.themeMode.value
                : ThemeMode.dark;
            final isDarkMode = currentMode == ThemeMode.dark;

            return ListTile(
              leading: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode ? Colors.amber : Colors.orangeAccent,
              ),
              title: const Text('App Visual Theme'),
              subtitle:
                  Text(isDarkMode ? 'Dark Arena Theme' : 'Light Arena Theme'),
              trailing: Switch(
                value: isDarkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  if (Get.isRegistered<ThemeService>()) {
                    ThemeService.to.switchThemeMode(
                        val ? ThemeMode.dark : ThemeMode.light);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 6. Prominent Logout Action Card
  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLogoutConfirmationDialog(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log Out & Purge Device Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final RxBool isLoggingOut = false.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Log Out of Arena?',
            style: TextStyle(color: context.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.power_settings_new_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out? This action will wipe session tokens and purge local match cache.',
                style: TextStyle(
                    fontSize: 13, color: context.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            if (isLoggingOut.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.error),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      isLoggingOut.value = true;
                      await AuthService.to.logout();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
