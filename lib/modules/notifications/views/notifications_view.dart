import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import 'admin_notifications_view.dart';
import '../../manager/views/manager_notifications_view.dart';
import 'player_notifications_view.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final roleId = AuthService.to.currentUser.value?.roleId ?? 3;

    if (roleId == 1) {
      return AdminNotificationsView();
    } else if (roleId == 2) {
      return const ManagerNotificationsView();
    } else {
      return PlayerNotificationsView();
    }
  }
}
