import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/profile_image_viewer_page.dart';
import '../../../data/models/user_model.dart';

class ManagerEditProfileView extends StatefulWidget {
  const ManagerEditProfileView({super.key});

  @override
  State<ManagerEditProfileView> createState() => _ManagerEditProfileViewState();
}

class _ManagerEditProfileViewState extends State<ManagerEditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController nameController;
  late final TextEditingController cityController;
  late final TextEditingController bioController;
  final Rxn<DateTime> selectedDob = Rxn<DateTime>();

  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxString avatarUrl = ''.obs;

  @override
  void initState() {
    super.initState();
    final user = AuthService.to.currentUser.value;

    nameController = TextEditingController(text: user?.name ?? '');
    cityController = TextEditingController(text: user?.city ?? '');
    bioController =
        TextEditingController(text: 'Managing Smash Up India Turf');
    avatarUrl.value = user?.profileImageUrl ?? '';

    _loadManagerProfileData();
  }

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _loadManagerProfileData() async {
    try {
      final dioClient = Get.find<DioClient>();
      final response = await dioClient.dio.get('/manager/profile');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          nameController.text = data['name'].toString();
        }
        if (data['city'] != null && data['city'].toString().isNotEmpty) {
          cityController.text = data['city'].toString();
        }
        if (data['bio'] != null && data['bio'].toString().isNotEmpty) {
          bioController.text = data['bio'].toString();
        }
        if (data['profile_image_url'] != null) {
          avatarUrl.value = data['profile_image_url'].toString();
        }
        if (data['date_of_birth'] != null || data['dob'] != null) {
          final rawDob = (data['date_of_birth'] ?? data['dob']).toString();
          if (rawDob.isNotEmpty) {
            selectedDob.value = AppDateUtils.parseDate(rawDob);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      Get.back();

      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      isUploadingAvatar.value = true;

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
        final newUrl =
            updated?['profile_image_url'] ?? updated?['avatarUrl'] ?? '';

        if (newUrl.isNotEmpty) {
          avatarUrl.value = newUrl;
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
              profileImageUrl: newUrl,
            );
          }
        }

        ErrorHandler.showSuccessSnackBar(
          'Success',
          'Profile photo updated successfully!',
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Upload Notice', e);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  void _showImageSourceModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you want to pick your profile photo',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary, size: 20),
              ),
              title: const Text('Take Photo via Camera',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Use your device camera to snap a new photo',
                  style: TextStyle(fontSize: 11)),
              onTap: () => _pickAndUploadImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF0284C7), size: 20),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Select an existing photo from device files',
                  style: TextStyle(fontSize: 11)),
              onTap: () => _pickAndUploadImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
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
          _showImageSourceModal(context);
        },
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  Widget _buildDefaultAvatar(String name, {required double size}) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    return Container(
      width: size,
      height: size,
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvatarHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.to.currentUser.value;
    final name = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()
        : (user?.name ?? 'Manager');

    return Obx(() {
      final rawAvatar = avatarUrl.value;
      final resolvedAvatar = rawAvatar.resolvedImageUrl;

      return Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      _openProfileImageViewer(context, name, resolvedAvatar),
                  child: Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: resolvedAvatar.isValidNetworkUrl
                          ? CachedNetworkImage(
                              imageUrl: resolvedAvatar!,
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) =>
                                  _buildDefaultAvatar(name, size: 104),
                            )
                          : _buildDefaultAvatar(name, size: 104),
                    ),
                  ),
                ),

                // Uploading progress overlay
                Obx(() {
                  if (!isUploadingAvatar.value) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),

                // Camera Edit Badge Icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceModal(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap camera icon to change photo',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDobField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fieldFillColor =
        isDark ? AppColors.darkInputBg : const Color(0xFFFAFAFA);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDob.value ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) selectedDob.value = picked;
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fieldFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Text(
                      selectedDob.value != null
                          ? AppDateUtils.formatIsoDate(selectedDob.value!)
                          : 'YYYY-MM-DD',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDob.value != null
                            ? primaryTextColor
                            : hintTextColor,
                        fontWeight: selectedDob.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    color: hintTextColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final city = cityController.text.trim();
    final bio = bioController.text.trim();

    if (name.isEmpty) {
      ErrorHandler.showWarningSnackBar(
        'Validation Error',
        'Full name cannot be empty.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final dioClient = Get.find<DioClient>();
      await dioClient.dio.put(
        '/auth/profile',
        data: {
          'name': name,
          'city': city,
          'bio': bio,
          if (selectedDob.value != null)
            'dateOfBirth': AppDateUtils.formatIsoDate(selectedDob.value!),
        },
      );

      final user = AuthService.to.currentUser.value;
      if (user != null) {
        AuthService.to.currentUser.value = UserModel(
          id: user.id,
          name: name,
          email: user.email,
          phone: user.phone,
          roleName: user.roleName,
          roleId: user.roleId,
          status: user.status,
          city: city,
          profileImageUrl: avatarUrl.value.isNotEmpty
              ? avatarUrl.value
              : user.profileImageUrl,
        );
      }

      ErrorHandler.showSuccessSnackBar(
        'Profile Updated',
        'Manager profile details saved successfully!',
      );

      Get.back();
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Update Failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final fieldFillColor =
        isDark ? AppColors.darkInputBg : const Color(0xFFFAFAFA);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarHeader(context),
                const SizedBox(height: 24),

                // Personal Information Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Full Name Field
                      Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: AppColors.primary, size: 22),
                          filled: true,
                          fillColor: fieldFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // City Field
                      Text(
                        'City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cityController,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter city',
                          prefixIcon: const Icon(Icons.location_city_rounded,
                              color: AppColors.primary, size: 22),
                          filled: true,
                          fillColor: fieldFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Manager Bio Field
                      Text(
                        'Manager Bio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: bioController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe your role or turf bio',
                          prefixIcon: const Icon(Icons.notes_rounded,
                              color: AppColors.primary, size: 22),
                          filled: true,
                          fillColor: fieldFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Date of Birth Field
                      _buildDobField(context),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Changes Button
                Obx(() {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: isLoading.value ? null : _saveChanges,
                      child: isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
