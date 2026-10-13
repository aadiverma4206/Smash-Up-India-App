import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';

class AdminCreateManagerView extends GetView<AdminController> {
  AdminCreateManagerView({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cityController =
      TextEditingController(text: 'Raipur');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void _generateStrongPassword() {
    passwordController.text = 'Manager@2026!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Provision Turf Manager'),
        centerTitle: true,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          final isTabletOrDesktop = deviceType == DeviceType.tablet ||
              deviceType == DeviceType.desktop;

          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: isTabletOrDesktop ? 32.0 : 16.0,
                right: isTabletOrDesktop ? 32.0 : 16.0,
                top: 12.0,
                bottom: 24.0,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTabletOrDesktop ? 600 : double.infinity,
                ),
                decoration: isTabletOrDesktop
                    ? BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                padding: EdgeInsets.all(isTabletOrDesktop ? 24.0 : 0.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Turf Manager Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provision accounts for local turf managers. Required fields include full name, email, phone number, and a strong temporary password.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey.shade700,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Manager Full Name
                      AppTextField(
                        label: 'Manager Full Name',
                        hint: 'Manager Name',
                        controller: nameController,
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter Manager Name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Manager Email
                      AppTextField(
                        label: 'Manager Email',
                        hint: 'manager@example.com',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.mail_outline_rounded,
                            color: AppColors.primary, size: 20),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter Valid Email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      AppTextField(
                        label: 'Phone Number',
                        hint: '+919876543210',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: AppColors.primary, size: 20),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Enter Valid Phone (+91...)'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // City
                      AppTextField(
                        label: 'City',
                        hint: 'Raipur',
                        controller: cityController,
                        prefixIcon: const Icon(Icons.location_city_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(height: 16),

                      // Temporary Password Row Label & Auto Generate Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Temporary Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _generateStrongPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.auto_awesome_rounded,
                                size: 15, color: AppColors.primary),
                            label: const Text(
                              'Auto Generate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: '',
                        hint: 'Manager@2026!',
                        controller: passwordController,
                        obscureText: false,
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary, size: 20),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter Password';
                          if (v.length < 8) {
                            return 'Minimum 8 characters required';
                          }
                          final RegExp pwdRegex = RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$');
                          if (!pwdRegex.hasMatch(v)) {
                            return 'Must have upper, lower, number & special char (@\$!%*?&#)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Obx(
                        () => AppButton(
                          text: 'Provision Manager Account',
                          showArrow: true,
                          isLoading: controller.isLoading.value,
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {
                              controller.createManager(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                password: passwordController.text,
                                city: cityController.text.trim(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
