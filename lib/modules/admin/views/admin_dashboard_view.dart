import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_controller.dart';
import '../../manager/views/manager_history_view.dart';
import '../../cctv/views/media_server_cctv_view.dart';
import 'admin_profile_view.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_shimmer.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late final AdminController controller;
  late final ScrollController _scrollController;
  final ValueNotifier<double> _headerProgress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminController>();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerProgress.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      final double pixels = notification.metrics.pixels;
      final double newProgress = (pixels / 80.0).clamp(0.0, 1.0);
      if (_headerProgress.value != newProgress) {
        _headerProgress.value = newProgress;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        if (isLandscape ||
            deviceType == DeviceType.desktop ||
            deviceType == DeviceType.tablet) {
          return _buildTabletDesktopLayout(context);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, {bool showBottomNav = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        final currentIndex = controller.selectedNavIndex.value.clamp(0, 3);

        return IndexedStack(
          index: currentIndex,
          children: [
            _buildMobileHomeTab(context),
            const ManagerHistoryView(),
            currentIndex == 2
                ? const MediaServerCctvScreen()
                : const SizedBox.shrink(),
            const AdminProfileView(),
          ],
        );
      }),
      bottomNavigationBar: showBottomNav
          ? Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                      top: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFEEEEEE),
                          width: 1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: controller.selectedNavIndex.value.clamp(0, 3),
                  onTap: (index) {
                    controller.changeNavIndex(index);
                    if (index == 0) controller.loadDashboard();
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Theme.of(context).cardColor,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  selectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.bold),
                  items: [
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          children: [
                            Container(
                              height: 3,
                              width: 20,
                              color: controller.selectedNavIndex.value == 0
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.apps_rounded, size: 22),
                          ],
                        ),
                      ),
                      label: 'Dashboard',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.history_rounded, size: 22),
                      label: 'History',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.videocam_rounded, size: 22),
                      label: 'CCTV',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded, size: 22),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMobileHomeTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color solidHeaderColor =
        isDark ? const Color(0xFF130722) : Theme.of(context).cardColor;
    final Color borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);

    return Obx(() {
      if (controller.isLoading.value && controller.dashboard.value == null) {
        return _buildHomeSkeletonView(context);
      }
      return Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: RefreshIndicator(
              onRefresh: controller.loadDashboard,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderBackground(context),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAdminPillBar(context),
                          const SizedBox(height: 18),
                          _buildCircularActionsGrid(context),
                          const SizedBox(height: 20),
                          _buildMetricsSection(context),
                          const SizedBox(height: 20),
                          _buildQuickModulesGrid(context),
                          const SizedBox(height: 20),
                          _buildReferAdBanner(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _headerProgress,
              builder: (context, progress, child) {
                final Color currentBgColor = Color.lerp(
                  Colors.transparent,
                  solidHeaderColor,
                  progress,
                )!;

                final Color currentBorderColor = Color.lerp(
                  Colors.transparent,
                  borderColor,
                  progress,
                )!;

                return Container(
                  decoration: BoxDecoration(
                    color: currentBgColor,
                    border: Border(
                      bottom: BorderSide(
                        color: currentBorderColor,
                        width: 1,
                      ),
                    ),
                    boxShadow: progress > 0.05
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.12 * progress),
                              blurRadius: 8 * progress,
                              offset: Offset(0, 2 * progress),
                            ),
                          ]
                        : null,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildLogoWidget(context),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Opacity(
                                opacity: progress,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: _buildTitleWidget(context),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNotificationButton(context),
                              const SizedBox(width: 8),
                              _buildProfileButton(context),
                              const SizedBox(width: 8),
                              _buildLogoutAvatar(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTabletDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Obx(
            () => NavigationRail(
              backgroundColor: Theme.of(context).cardColor,
              selectedIndex: controller.selectedNavIndex.value.clamp(0, 3),
              onDestinationSelected: (index) {
                controller.changeNavIndex(index);
                if (index == 0) controller.loadDashboard();
                if (index == 1) Get.toNamed('/manager/cctv');
                if (index == 2) Get.toNamed(Routes.adminProfile);
                if (index == 3) _confirmLogout(context);
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF00C853)),
              unselectedIconTheme: IconThemeData(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600),
              selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                  fontSize: 11),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.apps_rounded), label: Text('Dashboard')),
                NavigationRailDestination(
                    icon: Icon(Icons.videocam_rounded), label: Text('CCTV')),
                NavigationRailDestination(
                    icon: Icon(Icons.person_rounded), label: Text('Profile')),
                NavigationRailDestination(
                    icon: Icon(Icons.logout_rounded), label: Text('Logout')),
              ],
            ),
          ),
          VerticalDivider(
              thickness: 1,
              width: 1,
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE)),
          Expanded(
            child: _buildMobileLayout(context, showBottomNav: false),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSkeletonView(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
                child: const AppShimmer(
                  width: double.infinity,
                  height: 250,
                  borderRadius: 0,
                  enable3D: false,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const AppShimmer(
                        width: 38,
                        height: 38,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 10),
                      const AppShimmer(width: 120, height: 18, borderRadius: 6),
                      const Spacer(),
                      const AppShimmer(
                        width: 38,
                        height: 38,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 8),
                      const AppShimmer(
                        width: 38,
                        height: 38,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 8),
                      const AppShimmer(
                        width: 38,
                        height: 38,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 8),
                      const AppShimmer(
                        width: 38,
                        height: 38,
                        shape: BoxShape.circle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppShimmer(
                  width: double.infinity,
                  height: 52,
                  borderRadius: 30,
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Column(
                        children: const [
                          AppShimmer(
                            width: 50,
                            height: 50,
                            shape: BoxShape.circle,
                          ),
                          SizedBox(height: 8),
                          AppShimmer(width: 52, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const AppShimmer(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 14,
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(
                    3,
                    (index) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: AppShimmer(
                          width: double.infinity,
                          height: 65,
                          borderRadius: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: List.generate(
                    4,
                    (index) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: AppShimmer(
                          width: double.infinity,
                          height: 60,
                          borderRadius: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const AppShimmer(
                  width: double.infinity,
                  height: 110,
                  borderRadius: 16,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String homeHeaderImagePath = isDark
        ? 'assets/images/Home_page/dark.png'
        : 'assets/images/Home_page/light.png';

    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset(
              homeHeaderImagePath,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                color:
                    isDark ? const Color(0xFF07120E) : const Color(0xFF1E1035),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white54, size: 40),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoWidget(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/App_Logo/all_stars_arena_logo.png',
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF7E57C2),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Admin Portal',
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2D1B69),
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed('/notifications'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Obx(() {
      final user = AuthService.to.currentUser.value;
      final avatarUrl = user?.profileImageUrl ?? '';

      return InkWell(
        onTap: () => Get.toNamed(Routes.adminProfile),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: ClipOval(
            child: avatarUrl.isValidNetworkUrl
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF7E57C2),
                      size: 20,
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF7E57C2),
                      size: 20,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildLogoutAvatar(BuildContext context) {
    return InkWell(
      onTap: () => _confirmLogout(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.logout_rounded,
            color: AppColors.error,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPillBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF130722),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(Routes.adminAuditLogs),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'System Security & Audit Logs',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = [
      {
        'icon': Icons.sports_soccer_rounded,
        'title': 'Player Mgmt',
        'route': Routes.adminPlayers,
      },
      {
        'icon': Icons.badge_rounded,
        'title': 'Manager Mgmt',
        'route': Routes.adminManagers,
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Match History',
        'route': Routes.managerHistoryStandalone,
      },
      {
        'icon': Icons.videocam_rounded,
        'title': 'CCTV Network',
        'route': '/manager/cctv',
      },
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions.map((item) {
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (item.containsKey('action')) {
                  (item['action'] as VoidCallback)();
                } else {
                  Get.toNamed(item['route'] as String);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : const Color(0xFFE8F8F0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFA5D6A7),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          item['icon'] as IconData,
                          color: isDark
                              ? AppColors.primary
                              : const Color(0xFF130722),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = controller.dashboard.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'System Overview',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Get.toNamed('/admin/users'),
              child: const Text('Manage Users →',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Column(
          children: [
            Row(
              children: [
                _buildSmallStatCard(
                    context,
                    'Revenue',
                    '₹${d?.totalRevenue.toStringAsFixed(0) ?? "0"}',
                    Icons.payments_outlined),
                _buildSmallStatCard(context, 'Total Users',
                    '${d?.totalUsers ?? 0}', Icons.people_outline),
                _buildSmallStatCard(context, 'Managers',
                    '${d?.totalManagers ?? 0}', Icons.admin_panel_settings),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildSmallStatCard(context, 'Turf Clubs',
                    '${d?.totalClubs ?? 0}', Icons.stadium_outlined),
                _buildSmallStatCard(context, 'Active Games',
                    '${d?.activeRecordings ?? 0}', Icons.videocam_outlined),
                _buildSmallStatCard(
                    context,
                    'Refunds',
                    '₹${d?.totalRefunds.toStringAsFixed(0) ?? "0"}',
                    Icons.replay_outlined),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
      BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
              width: 1),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickModulesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modules = [
      {
        'icon': Icons.sports_soccer_rounded,
        'title': 'Players',
        'route': Routes.adminPlayers,
        'color': AppColors.primary
      },
      {
        'icon': Icons.admin_panel_settings_rounded,
        'title': 'Managers',
        'route': Routes.adminManagers,
        'color': const Color(0xFF0288D1)
      },
      {
        'icon': Icons.person_add_rounded,
        'title': 'Create Mgr',
        'route': '/admin/managers/create',
        'color': const Color(0xFF7B1FA2)
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Audit Logs',
        'route': Routes.adminAuditLogs,
        'color': const Color(0xFF2E7D32)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Management Modules',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : Colors.black87)),
        const SizedBox(height: 10),
        Row(
          children: modules.map((item) {
            final Color color = item['color'] as Color;
            return Expanded(
              child: InkWell(
                onTap: () {
                  if (item.containsKey('action')) {
                    (item['action'] as VoidCallback)();
                  } else {
                    Get.toNamed(item['route'] as String);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : color.withValues(alpha: 0.3)),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(item['icon'] as IconData, color: color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReferAdBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String referImagePath = isDark
        ? 'assets/images/Refer/dark.png'
        : 'assets/images/Refer/light.png';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          referImagePath,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Admin Log Out'),
        content:
            const Text('Are you sure you want to log out of the Admin Portal?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Get.back();
              await AuthService.to.logout();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
