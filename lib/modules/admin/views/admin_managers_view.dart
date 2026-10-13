import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/admin_models.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/theme/app_colors.dart';
import 'admin_user_detail_view.dart';

class AdminManagersView extends GetView<AdminController> {
  final bool showAppBar;

  AdminManagersView({super.key, this.showAppBar = true}) {
    scrollController.addListener(_onScroll);
  }

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.fetchManagers(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Manager Management'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: () => Get.toNamed('/admin/managers/create'),
                  tooltip: 'Add New Manager',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => controller.fetchManagers(),
                  tooltip: 'Refresh Managers',
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        child: ResponsiveBuilder(
          builder: (context, deviceType) {
            final isTabletOrDesktop = deviceType == DeviceType.tablet ||
                deviceType == DeviceType.desktop;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Column(
                children: [
                  // Search Bar
                  AppTextField(
                    label: '',
                    hint: 'Search Manager Email, Phone or Name...',
                    controller: searchController,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.grey, size: 20),
                      onPressed: () {
                        searchController.clear();
                        controller.onManagerSearchChanged('');
                      },
                    ),
                    onChanged: (val) {
                      controller.onManagerSearchChanged(val);
                    },
                    onSubmitted: (val) {
                      controller.onManagerSearchChanged(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Managers Content View
                  Expanded(
                    child: Obx(() {
                      // 1. 3D Shimmer Loading Skeleton
                      if (controller.isLoadingManagers.value &&
                          controller.managers.isEmpty) {
                        return _buildShimmerView(context, deviceType);
                      }

                      // 2. Empty State View
                      if (controller.managers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No turf managers found.',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Get.toNamed('/admin/managers/create'),
                                icon: const Icon(Icons.add,
                                    size: 18, color: Colors.white),
                                label: const Text('Create New Manager',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }

                      // 3. Responsive List / Grid View
                      return RefreshIndicator(
                        onRefresh: () async => controller.fetchManagers(),
                        child: isTabletOrDesktop
                            ? GridView.builder(
                                controller: scrollController,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      deviceType == DeviceType.desktop ? 3 : 2,
                                  childAspectRatio: 2.8,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: controller.managers.length +
                                    (controller.hasMoreManagers.value ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == controller.managers.length) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary),
                                    );
                                  }
                                  return _buildCompactUserTile(
                                      context, controller.managers[index]);
                                },
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: controller.managers.length +
                                    (controller.hasMoreManagers.value ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index == controller.managers.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0),
                                      child: Center(
                                        child: controller
                                                .isLoadingMoreManagers.value
                                            ? const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary)
                                            : const SizedBox.shrink(),
                                      ),
                                    );
                                  }
                                  final manager = controller.managers[index];
                                  return _buildCompactUserTile(
                                      context, manager);
                                },
                              ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 3D Animated Shimmer Loading Skeleton
  Widget _buildShimmerView(BuildContext context, DeviceType deviceType) {
    final isGrid =
        deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;
    if (isGrid) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: deviceType == DeviceType.desktop ? 3 : 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _buildSingleShimmerCard(context),
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _buildSingleShimmerCard(context),
    );
  }

  Widget _buildSingleShimmerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const AppShimmer(
            width: 44,
            height: 44,
            shape: BoxShape.circle,
            enable3D: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppShimmer(
                        width: 110,
                        height: 14,
                        borderRadius: 4,
                        enable3D: true),
                    AppShimmer(
                        width: 45, height: 12, borderRadius: 4, enable3D: true),
                  ],
                ),
                const SizedBox(height: 8),
                const AppShimmer(
                    width: 150, height: 12, borderRadius: 4, enable3D: true),
                const SizedBox(height: 6),
                const AppShimmer(
                    width: 90, height: 10, borderRadius: 4, enable3D: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserTile(BuildContext context, AdminUserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuspended = user.isSuspended;

    return Card(
      elevation: 1.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => AdminUserDetailView(userModel: user));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Avatar Image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSuspended ? AppColors.error : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: user.profileImageUrl.isValidNetworkUrl
                      ? CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _buildAvatarLetter(user),
                        )
                      : _buildAvatarLetter(user),
                ),
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Compact Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSuspended
                                ? AppColors.error.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.status,
                            style: TextStyle(
                              color: isSuspended
                                  ? AppColors.error
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          user.phone,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        if (user.city != null && user.city!.isNotEmpty) ...[
                          Text(
                            ' • ${user.city}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarLetter(AdminUserModel user) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
