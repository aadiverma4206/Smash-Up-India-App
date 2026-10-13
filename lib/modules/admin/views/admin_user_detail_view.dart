import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../app/theme/app_colors.dart';

class AdminUserDetailView extends StatefulWidget {
  final AdminUserModel? userModel;

  const AdminUserDetailView({super.key, this.userModel});

  @override
  State<AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView> {
  late AdminUserModel user;
  late final AdminController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminController>();
    if (widget.userModel != null) {
      user = widget.userModel!;
    } else if (Get.arguments is AdminUserModel) {
      user = Get.arguments as AdminUserModel;
    } else {
      user = AdminUserModel(
        id: 'N/A',
        name: 'User Detail',
        email: 'N/A',
        phone: 'N/A',
        roleId: 3,
        roleName: 'PLAYER',
        status: 'ACTIVE',
        createdAt: '',
      );
    }
  }

  void _toggleSuspendStatus() {
    final bool isCurrentlySuspended = user.isSuspended;
    final String actionText =
        isCurrentlySuspended ? 'Unlock / Reactivate' : 'Block / Suspend';
    final String dialogMessage = isCurrentlySuspended
        ? 'Are you sure you want to unlock and reactivate this user account?'
        : 'Are you sure you want to block and suspend this user account?';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionText Account'),
        content: Text(dialogMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCurrentlySuspended ? AppColors.primary : AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back();
              if (isCurrentlySuspended) {
                await controller.unsuspendUser(user.id);
                setState(() {
                  user = AdminUserModel(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    roleId: user.roleId,
                    roleName: user.roleName,
                    status: 'ACTIVE',
                    city: user.city,
                    profileImageUrl: user.profileImageUrl,
                    createdAt: user.createdAt,
                  );
                });
              } else {
                await controller.suspendUser(user.id);
                setState(() {
                  user = AdminUserModel(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    roleId: user.roleId,
                    roleName: user.roleName,
                    status: 'SUSPENDED',
                    city: user.city,
                    profileImageUrl: user.profileImageUrl,
                    createdAt: user.createdAt,
                  );
                });
              }
            },
            child: Text(
              actionText,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSuspended = user.isSuspended;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Profile Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSuspended
                                ? AppColors.error
                                : AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: (user.profileImageUrl != null &&
                                  user.profileImageUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: user.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      _buildAvatarFallback(),
                                )
                              : _buildAvatarFallback(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSuspended
                                ? AppColors.error
                                : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            isSuspended ? Icons.block : Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              user.roleName,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuspended
                              ? AppColors.error.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSuspended ? AppColors.error : Colors.green,
                          ),
                        ),
                        child: Text(
                          user.status,
                          style: TextStyle(
                            color: isSuspended
                                ? AppColors.error
                                : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User Info Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact & Personal Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                      context, Icons.email_outlined, 'Email', user.email),
                  _buildDetailRow(
                      context, Icons.phone_outlined, 'Phone', user.phone),
                  _buildDetailRow(
                    context,
                    Icons.location_city_outlined,
                    'City / Location',
                    user.city != null && user.city!.isNotEmpty
                        ? user.city!
                        : 'Not Specified',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Meta Information Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Metadata',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                      context, Icons.badge_outlined, 'User ID', user.id),
                  _buildDetailRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Registration Date',
                    user.createdAt.isNotEmpty
                        ? (user.createdAt.length >= 10
                            ? user.createdAt.substring(0, 10)
                            : user.createdAt)
                        : 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Block / Unlock Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _toggleSuspendStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSuspended ? AppColors.primary : AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: Icon(
                  isSuspended ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isSuspended
                      ? 'Unlock / Unsuspend User'
                      : 'Block / Suspend User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
