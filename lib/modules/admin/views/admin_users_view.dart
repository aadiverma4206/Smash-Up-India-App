import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../../../app/theme/app_colors.dart';
import 'admin_players_view.dart';
import 'admin_managers_view.dart';

class AdminUsersView extends GetView<AdminController> {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'User Management',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.sageGreenAppBar,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        body: Column(
          children: [
            // Ultra-Compact Segmented Pill Tab Bar
            Container(
              color: isDark
                  ? Theme.of(context).scaffoldBackgroundColor
                  : AppColors.sageGreenAppBar,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF475569),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Players'),
                    Tab(text: 'Managers'),
                  ],
                ),
              ),
            ),

            // Tab Content View
            Expanded(
              child: TabBarView(
                children: [
                  AdminPlayersView(showAppBar: false),
                  AdminManagersView(showAppBar: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
