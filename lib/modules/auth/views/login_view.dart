import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auto_fit_text.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: isWideScreen
          ? SafeArea(child: _buildWideScreenLayout(context, controller))
          : _buildMobileLayout(context, controller),
    );
  }

  /// Mobile / Portrait Layout
  Widget _buildMobileLayout(BuildContext context, AuthController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Sports Hero Image Banner extending to full top of screen
          _buildHeroImage(context, height: 230),

          // Main Form Section
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: _buildLoginForm(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  /// Wide Screen / Desktop / Tablet Layout
  Widget _buildWideScreenLayout(
      BuildContext context, AuthController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Left Side: Hero Image Banner
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeroImage(
                  context,
                  height: double.infinity,
                  borderRadius: 0,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AutoFitText(
                        'ALL STARS ARENA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'LIVE. PLAY. CONNECT. Your Ultimate Sports & Gaming Arena',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side: Login Form
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildLoginForm(context, controller),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hero Banner Image Widget with Fallback & Curved Bottom
  Widget _buildHeroImage(
    BuildContext context, {
    required double height,
    double borderRadius = 28,
  }) {
    const String sportsImageUrl =
        'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&q=80&w=1000';

    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: borderRadius > 0
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  )
                : BorderRadius.zero,
          ),
          child: ClipRRect(
            borderRadius: borderRadius > 0
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  )
                : BorderRadius.zero,
            child: CachedNetworkImage(
              imageUrl: sportsImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer,
                          size: 64, color: AppColors.primary),
                      SizedBox(height: 12),
                      AutoFitText(
                        'ALL STARS ARENA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Dark Gradient Overlay for optimal contrast
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius > 0
                  ? BorderRadius.only(
                      bottomLeft: Radius.circular(borderRadius),
                      bottomRight: Radius.circular(borderRadius),
                    )
                  : BorderRadius.zero,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Complete Form Widget matching design reference
  Widget _buildLoginForm(BuildContext context, AuthController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title: Welcome Back
          Row(
            children: [
              Flexible(
                child: AutoFitText(
                  'Welcome ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const AutoFitText(
                'Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Log in to continue your sports arena journey',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Reactive Error Banner inside the Form
          Obx(() {
            final err = controller.errorMessage.value;
            if (err.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      err,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Field 1: Email or Mobile Number
          AppTextField(
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            hint: 'Email or Mobile Number',
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: secondaryTextColor,
              size: 22,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email or mobile number';
              }
              final trimmed = value.trim();
              if (trimmed.contains('@')) {
                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(trimmed)) {
                  return 'Please enter a valid email address';
                }
              } else if (RegExp(r'^[0-9+\s-]+$').hasMatch(trimmed)) {
                final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly.length < 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Field 2: Password
          AppTextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            hint: 'Password',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: secondaryTextColor,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: secondaryTextColor,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const AutoFitText(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Primary Log In Button with right arrow
          Obx(() {
            final isLoading = controller.isLoading.value;
            return AppButton(
              text: 'Log In',
              showArrow: true,
              isLoading: isLoading,
              height: 52,
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  controller.login(
                    identifierController.text.trim(),
                    passwordController.text,
                  );
                }
              },
            );
          }),

          const SizedBox(height: 16),

          // ⚡ Quick Autofill Test Role Icons (Player, Manager, Admin)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ⚽ Player Autofill Button
              Tooltip(
                message: 'Autofill Player Credentials',
                child: InkWell(
                  onTap: () {
                    identifierController.text = 'player@gmail.com';
                    passwordController.text = 'Player@123';
                    controller.errorMessage.value = '';
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 🏟️ Manager Autofill Button
              Tooltip(
                message: 'Autofill Manager Credentials',
                child: InkWell(
                  onTap: () {
                    identifierController.text = 'roshan12@gmail.com';
                    passwordController.text = 'Roshan@123';
                    controller.errorMessage.value = '';
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Icon(
                      Icons.stadium_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 🛡️ Admin Autofill Button
              Tooltip(
                message: 'Autofill Admin Credentials',
                child: InkWell(
                  onTap: () {
                    identifierController.text = 'aadiverma4206@gmail.com';
                    passwordController.text = 'Admin@123';
                    controller.errorMessage.value = '';
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 18,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider: —— OR ——
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AutoFitText(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Social Button 1: Continue with Google
          _buildSocialButton(
            context,
            label: 'Continue with Google',
            icon: _buildGoogleLogo(),
            onTap: () {
              Get.snackbar(
                'Social Login',
                'Google Sign-In selected',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primary,
                colorText: Colors.white,
              );
            },
          ),
          const SizedBox(height: 12),

          // Social Button 2: Continue with Apple
          _buildSocialButton(
            context,
            label: 'Continue with Apple',
            icon: Icon(
              Icons.apple,
              size: 22,
              color: primaryTextColor,
            ),
            onTap: () {
              Get.snackbar(
                'Social Login',
                'Apple Sign-In selected',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: isDark ? Colors.white : Colors.black,
                colorText: isDark ? Colors.black : Colors.white,
              );
            },
          ),

          const SizedBox(height: 28),

          // Footer Text: Don't have an account? Create Account
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.register),
                  child: const AutoFitText(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Social Login Pill Button
  Widget _buildSocialButton(
    BuildContext context, {
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Flexible(
              child: AutoFitText(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom Google 'G' Icon
  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEA4335),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
