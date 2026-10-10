import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/errors/error_handler.dart';
import '../../../app/theme/app_colors.dart';
import '../../support/widgets/support_legal_cards.dart';

class ManagerProfileView extends StatefulWidget {
  const ManagerProfileView({super.key});

  @override
  State<ManagerProfileView> createState() => _ManagerProfileViewState();
}

class _ManagerProfileViewState extends State<ManagerProfileView> {
  final ImagePicker _picker = ImagePicker();
  final RxBool isUploading = false.obs;
  final RxMap<String, dynamic> profileData = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    fetchManagerProfile();
  }

  Future<void> fetchManagerProfile() async {
    isLoading.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      final response = await dioClient.dio.get('/manager/profile');
      if (response.data != null && response.data['data'] != null) {
        profileData.assignAll(response.data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', 'Failed to load manager profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      Get.back(); // close bottom sheet first

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
        final newAvatarUrl = updated?['profile_image_url'] ?? '';

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
          'Profile photo updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Upload Issue',
        'Could not update profile photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
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
                  'Upload Profile Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                  title: const Text('Take Photo from Camera'),
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
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
        title: const Text('Manager Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchManagerProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (isLoading.value) {
            return const AppLoader(message: 'Loading manager profile details...');
          }

          final name = profileData['name'] ?? user?.name ?? 'Club Manager';
          final email = profileData['email'] ?? user?.email ?? 'manager@allstarsarena.com';
          final phone = profileData['phone'] ?? user?.phone ?? '+91 9876543210';
          final avatarUrl = profileData['profile_image_url'] ?? user?.profileImageUrl ?? '';
          final clubName = profileData['club_name'] ?? 'All Stars Arena Turf';
          final clubAddress = profileData['club_address'] ?? 'VIP Road, Raipur';

          return RefreshIndicator(
            onRefresh: fetchManagerProfile,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    // 👤 AVATAR SECTION WITH CAMERA OVERLAY
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    )
                                  : null,
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
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          if (isUploading.value)
                            const Positioned.fill(
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'CLUB MANAGER',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 💳 ACCOUNT DETAILS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Account Details',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                              ),
                            ],
                          ),
                          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200, height: 20),
                          _buildInfoRow(context, 'Full Name', name, Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Email Address', email, Icons.email_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Phone Number', phone, Icons.phone_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🏟️ ASSIGNED TURF CLUB CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Assigned Turf Club',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                              ),
                            ],
                          ),
                          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200, height: 20),
                          _buildInfoRow(context, 'Turf Club Name', clubName, Icons.sports_soccer_rounded),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Location Address', clubAddress, Icons.location_on_outlined),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Managed Pitches', 'Court 1 (Turf A) & Court 2 (Turf B)', Icons.grid_view_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ❓ HELP & SUPPORT AND LEGAL SECTION
                    const SupportAndLegalSection(),
                    const SizedBox(height: 24),

                    // 🚪 LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          backgroundColor: Theme.of(context).cardColor,
                        ),
                        onPressed: () => AuthService.to.logout(),
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                        label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
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
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
