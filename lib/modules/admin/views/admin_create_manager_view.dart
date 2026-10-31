import 'dart:math';
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
  final TextEditingController cityController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isPasswordVisible = false.obs;

  void _generateStrongPassword() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const uppers = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = r'@#$!';

    final p1 = uppers[random.nextInt(uppers.length)];
    final p2 = chars[random.nextInt(chars.length)] +
        chars[random.nextInt(chars.length)];
    final p3 = numbers[random.nextInt(numbers.length)] +
        numbers[random.nextInt(numbers.length)] +
        numbers[random.nextInt(numbers.length)];
    final p4 = symbols[random.nextInt(symbols.length)];

    passwordController.text = 'Mgr$p1$p2$p3$p4';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Create Manager',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrDesktop ? 24.0 : 16.0,
                vertical: 16.0,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTabletOrDesktop ? 560 : double.infinity,
                ),
                decoration: BoxDecoration(
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
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Manager Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Register a new venue manager account.',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFF1F5F9),
                        height: 1,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Manager Full Name',
                        hint: 'Name',
                        controller: nameController,
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 20),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter manager name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Manager Email',
                        hint: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.mail_outline_rounded,
                            color: AppColors.primary, size: 20),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!GetUtils.isEmail(v.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Phone Number',
                        hint: 'Mobile No.',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: AppColors.primary, size: 20),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          final cleanPhone = v.replaceAll(RegExp(r'\D'), '');
                          if (cleanPhone.length < 10) {
                            return 'Please enter valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'City / Region',
                        hint: 'City',
                        controller: cityController,
                        prefixIcon: const Icon(Icons.location_city_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(height: 16),
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
                                  : const Color(0xFF0F172A),
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
                            icon: const Icon(Icons.key_rounded,
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
                      Obx(
                        () => AppTextField(
                          label: '',
                          hint: 'Password',
                          controller: passwordController,
                          obscureText: !isPasswordVisible.value,
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible.value
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: isPasswordVisible.toggle,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter password';
                            }
                            if (v.length < 8) {
                              return 'Minimum 8 characters required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => AppButton(
                          text: 'Create Manager Account',
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
