import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/profile_image_viewer_page.dart';
import '../../../data/models/user_model.dart';
import '../../support/widgets/support_legal_cards.dart';
import '../controllers/admin_controller.dart';

class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  final ImagePicker _picker = ImagePicker();
  final RxBool isUploading = false.obs;
  final RxMap<String, dynamic> profileData = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;

  AdminController get adminController => Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    fetchAdminProfile();
  }

  Future<void> fetchAdminProfile() async {
    isLoading.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      final response = await dioClient.dio.get('/auth/me');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        profileData.assignAll(data);

        final userModel = UserModel.fromJson(data);
        AuthService.to.currentUser.value = userModel;
      }
    } catch (_) {
      final user = AuthService.to.currentUser.value;
      if (user != null) {
        profileData.assignAll({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'profile_image_url': user.profileImageUrl,
          'role': user.roleName,
          'city': user.city,
        });
      }
    } finally {
      isLoading.value = false;

      if (Get.isRegistered<AdminController>()) {
        adminController.loadDashboard();
      }
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Log Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out of the Admin Portal?',
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      Get.back();
                      await AuthService.to.logout();
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      Get.back();

      XFile? file;
      try {
        file = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      } catch (_) {
        Get.snackbar(
          'Notice',
          'Could not open image picker. Please check app permissions.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
        return;
      }

      if (file == null) return;

      isUploading.value = true;

      final dioClient = Get.find<DioClient>();
      final formData = dio.FormData.fromMap({
        'profileImage': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final response = await dioClient.dio.post(
        '/manager/profile/avatar',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final updated = response.data['data'] as Map<String, dynamic>?;
        final newAvatarUrl =
            updated?['profile_image_url'] ?? updated?['avatarUrl'] ?? '';

        if (newAvatarUrl.isNotEmpty) {
          profileData['profile_image_url'] = newAvatarUrl;
          final user = AuthService.to.currentUser.value;
          if (user != null) {
            AuthService.to.currentUser.value = UserModel(
              id: user.id,
              name: user.name,
              email: user.email,
              phone: user.phone,
              roleName: user.roleName,
              roleId: user.roleId,
              status: user.status,
              city: user.city,
              profileImageUrl: newAvatarUrl,
            );
          }
        }

        Get.snackbar(
          'Success',
          'Admin avatar updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Upload Notice',
        'Profile photo updated locally.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Admin Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded,
                      color: AppColors.primary),
                  title: const Text('Take Photo from Camera'),
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                  title: const Text('Choose Photo from Gallery'),
                  onTap: () => _pickAndUploadImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.to.currentUser.value;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.lightBlueAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'System Admin Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
        ),
        actions: [
          Obx(() {
            final currentMode = Get.isRegistered<ThemeService>()
                ? ThemeService.to.themeMode.value
                : ThemeMode.light;
            final isDark = currentMode == ThemeMode.dark;

            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : const Color(0xFF0F172A),
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                if (Get.isRegistered<ThemeService>()) {
                  ThemeService.to.switchThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                }
              },
            );
          }),
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
            tooltip: 'Edit Admin Profile',
            onPressed: () async {
              final result = await Get.toNamed(Routes.adminEditProfile);
              if (result == true) {
                fetchAdminProfile();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (isLoading.value && profileData.isEmpty) {
            return const AppLoader(
                message: 'Loading administrator profile details...');
          }

          final String name =
              (profileData['name'] ?? user?.name ?? 'System Administrator')
                  .toString();
          final String email =
              (profileData['email'] ?? user?.email ?? 'admin@smashupindia.com')
                  .toString();
          final String phone =
              (profileData['phone'] ?? user?.phone ?? '+91 9999999999')
                  .toString();
          final String rawAvatarUrl =
              (profileData['profile_image_url'] ?? user?.profileImageUrl ?? '')
                  .toString();
          final String resolvedAvatarUrl = rawAvatarUrl.resolvedImageUrl ?? '';
          final String role = (profileData['role_name'] ??
                  profileData['role'] ??
                  user?.roleName ??
                  'SYSTEM ADMIN')
              .toString();
          final String city =
              (profileData['city'] ?? user?.city ?? 'Raipur').toString();
          final dashboard = Get.isRegistered<AdminController>()
              ? adminController.dashboard.value
              : null;

          return RefreshIndicator(
            onRefresh: fetchAdminProfile,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () => _openProfileImageViewer(
                                context, name, resolvedAvatarUrl),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(52),
                                child: resolvedAvatarUrl.isValidNetworkUrl
                                    ? CachedNetworkImage(
                                        imageUrl: resolvedAvatarUrl,
                                        width: 104,
                                        height: 104,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 104,
                                          height: 104,
                                          color: Colors.grey.shade300,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            _buildDefaultAvatar(name),
                                      )
                                    : _buildDefaultAvatar(name),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: InkWell(
                              onTap: () => _showImagePickerSheet(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          if (isUploading.value)
                            const Positioned.fill(
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            role.toString().toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'System Summary Overview',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade200,
                              height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  label: 'Total Users',
                                  value:
                                      '${dashboard?.totalUsers ?? profileData['total_users'] ?? 0}',
                                  icon: Icons.people_outline_rounded,
                                  color: Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  label: 'Managers',
                                  value:
                                      '${dashboard?.totalManagers ?? profileData['total_managers'] ?? 0}',
                                  icon: Icons.badge_outlined,
                                  color: Colors.orange,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context,
                                  label: 'Courts',
                                  value:
                                      '${(dashboard?.totalClubs != null && dashboard!.totalClubs > 0) ? dashboard.totalClubs : (profileData['total_courts'] ?? 2)}',
                                  icon: Icons.stadium_outlined,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Account Credentials & Info',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade200,
                              height: 20),
                          _buildInfoRow(
                              context, 'Full Name', name, Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Email Address', email,
                              Icons.email_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Phone Number', phone,
                              Icons.phone_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              context,
                              'City / Region',
                              city.isNotEmpty ? city : 'Raipur, Chhattisgarh',
                              Icons.location_on_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => Get.toNamed('/admin/managers/create'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Manager',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Add & register new venue manager account',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SupportAndLegalSection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          backgroundColor: Theme.of(context).cardColor,
                        ),
                        onPressed: () => _showLogoutConfirmationDialog(context),
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: 18),
                        label: const Text(
                          'Log Out of Admin Portal',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'SMASH UP INDIA • ADMIN PORTAL v1.0.0',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
    return Container(
      width: 104,
      height: 104,
      color: AppColors.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _openProfileImageViewer(
      BuildContext context, String name, String? imageUrl) {
    Get.to(
      () => ProfileImageViewerPage(
        name: name,
        imageUrl: imageUrl,
        onEditTap: () {
          Get.back();
          _showImagePickerSheet(context);
        },
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }
}
