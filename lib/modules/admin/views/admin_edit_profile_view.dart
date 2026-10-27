import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/user_model.dart';

class AdminEditProfileView extends StatefulWidget {
  const AdminEditProfileView({super.key});

  @override
  State<AdminEditProfileView> createState() => _AdminEditProfileViewState();
}

class _AdminEditProfileViewState extends State<AdminEditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _emailController;

  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxString avatarUrl = ''.obs;

  @override
  void initState() {
    super.initState();
    final user = AuthService.to.currentUser.value;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    avatarUrl.value = user?.profileImageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      Get.back();

      final file = await _picker.pickImage(
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
        }

        ErrorHandler.showSuccessSnackBar(
            'Success', 'Admin photo uploaded successfully!');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Upload Notice', e);
    } finally {
      isUploadingAvatar.value = false;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      final response = await dioClient.dio.put(
        '/auth/profile',
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
          'profileImageUrl': avatarUrl.value,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final updatedUser = UserModel.fromJson(data);
        AuthService.to.currentUser.value = updatedUser;
      }

      ErrorHandler.showSuccessSnackBar(
          'Profile Updated', 'Admin details updated successfully!');

      Get.back(result: true);
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Update Failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.sageGreenAppBar,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Edit Admin Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Picker Section
                Center(
                  child: Stack(
                    children: [
                      Obx(() {
                        final validUrl =
                            ImageUtils.resolveImageUrl(avatarUrl.value);
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: validUrl != null
                                ? CachedNetworkImageProvider(validUrl)
                                : null,
                            child: validUrl == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showImagePickerSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SYSTEM ADMINISTRATOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Form Fields Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFEEEEEE),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Enter full name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Phone Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Enter phone number',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Phone Number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('City / Region'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cityController,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Enter city or region',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Email Address (Read-only)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'Email address',
                          icon: Icons.email_outlined,
                          isReadOnly: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Save Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
      ),
      suffixIcon: isReadOnly
          ? Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color:
                  isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
            )
          : null,
      filled: true,
      fillColor: isReadOnly
          ? (isDark ? AppColors.darkInputBg : const Color(0xFFF3F4F6))
          : Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
