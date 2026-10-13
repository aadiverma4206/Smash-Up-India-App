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
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.sports_soccer_rounded, size: 20),
                text: 'Players',
              ),
              Tab(
                icon: Icon(Icons.admin_panel_settings_rounded, size: 20),
                text: 'Managers',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminPlayersView(showAppBar: false),
            AdminManagersView(showAppBar: false),
          ],
        ),
      ),
    );
  }
}
