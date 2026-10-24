import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/player_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/profile_image_viewer_page.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/errors/error_handler.dart';
import '../../../app/theme/app_colors.dart';

class EditProfileView extends GetView<PlayerController> {
  EditProfileView({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final Rxn<DateTime> selectedDob = Rxn<DateTime>();

  void _initProfileData() {
    final p = controller.profile.value;
    if (p != null) {
      if (nameController.text.isEmpty) nameController.text = p.name;
      if (bioController.text.isEmpty) bioController.text = p.bio ?? '';
      if (cityController.text.isEmpty) cityController.text = p.city;

      if (selectedDob.value == null &&
          p.dateOfBirth != null &&
          p.dateOfBirth!.isNotEmpty) {
        selectedDob.value = AppDateUtils.parseDate(p.dateOfBirth!);
      }
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
              onTap: () async {
                Get.back();
                await _pickAndUploadImage(ImageSource.camera);
              },
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
              onTap: () async {
                Get.back();
                await _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        await controller.uploadAvatar(pickedFile.path);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Image Picker Error', e);
    }
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
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
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

    return Obx(() {
      final p = controller.profile.value;
      final name = p?.name ?? nameController.text.trim();
      final rawAvatar = p?.avatarUrl ?? '';
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
                  if (!controller.isUploadingAvatar.value) {
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
            const SizedBox(height: 6),
            Text(
              'Tap camera icon to change photo',
              style: TextStyle(
                fontSize: 11,
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
    final fieldFillColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                          : 'Select Date of Birth',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: selectedDob.value != null
                            ? primaryTextColor
                            : hintTextColor,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: hintTextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _initProfileData();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isDesktop = deviceType == DeviceType.desktop;
          final maxContainerWidth = isDesktop ? 600.0 : double.infinity;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxContainerWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Centered Profile Avatar Section
                    _buildAvatarHeader(context),

                    const SizedBox(height: 16),

                    // Personal Information Form Card
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_pin_rounded,
                                    size: 18, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Full Name',
                            controller: nameController,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'City',
                            controller: cityController,
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Player Bio',
                            hint: 'Write a short bio...',
                            controller: bioController,
                            maxLines: 2,
                            prefixIcon: const Icon(
                              Icons.notes_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDobField(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Changes Button
                    Obx(
                      () => AppButton(
                        text: 'Save Changes',
                        showArrow: true,
                        isLoading: controller.isLoading.value,
                        onPressed: () {
                          controller.updateProfile(
                            name: nameController.text.trim(),
                            bio: bioController.text.trim(),
                            city: cityController.text.trim(),
                            dateOfBirth: selectedDob.value != null
                                ? AppDateUtils.formatIsoDate(selectedDob.value!)
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
