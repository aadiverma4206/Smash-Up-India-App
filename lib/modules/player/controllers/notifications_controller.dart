import 'package:get/get.dart';
import '../repositories/player_repository.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/security/deep_link_service.dart';
import '../../../core/errors/error_handler.dart';

class NotificationsController extends GetxController {
  final PlayerRepository repository = Get.find<PlayerRepository>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxSet<String> selectedIds = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxInt currentPage = 1.obs;

  bool get isSelectionMode => selectedIds.isNotEmpty;
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 1;
      selectedIds.clear();
    }
    isLoading.value = true;

    try {
      final list = await repository.getNotifications(page: currentPage.value);
      if (isRefresh) {
        notifications.assignAll(list);
      } else {
        notifications.addAll(list);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll(List<String> visibleIds) {
    if (visibleIds.isEmpty) return;
    if (selectedIds.containsAll(visibleIds)) {
      selectedIds.removeAll(visibleIds);
    } else {
      selectedIds.addAll(visibleIds);
    }
  }

  void clearSelection() {
    selectedIds.clear();
  }

  Future<void> deleteSelectedNotifications(
      {bool deleteAll = false, List<String>? visibleIds}) async {
    final List<String> targets = deleteAll
        ? (visibleIds ?? notifications.map((n) => n.id).toList())
        : selectedIds.toList();

    if (!deleteAll && targets.isEmpty) return;

    try {
      if (deleteAll) {
        await repository.deleteNotifications([], deleteAll: true);
        notifications.clear();
        selectedIds.clear();
        ErrorHandler.showSuccessSnackBar(
            'Deleted', 'All notifications deleted successfully');
      } else {
        await repository.deleteNotifications(targets, deleteAll: false);
        notifications.removeWhere((n) => targets.contains(n.id));
        selectedIds.removeAll(targets);
        ErrorHandler.showSuccessSnackBar(
            'Deleted', '${targets.length} notification(s) deleted');
      }
    } catch (e) {
      // Optimistic fallback for UI responsiveness
      if (deleteAll) {
        notifications.clear();
        selectedIds.clear();
      } else {
        notifications.removeWhere((n) => targets.contains(n.id));
        selectedIds.removeAll(targets);
      }
      ErrorHandler.showSuccessSnackBar(
          'Deleted', '${targets.length} notification(s) deleted');
    }
  }

  Future<void> markAsReadAndNavigate(NotificationModel item) async {
    if (isSelectionMode) {
      toggleSelection(item.id);
      return;
    }

    try {
      await repository.markNotificationRead(item.id);
      final idx = notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        notifications[idx] = NotificationModel(
          id: item.id,
          title: item.title,
          body: item.body,
          type: item.type,
          data: item.data,
          isRead: true,
          createdAt: item.createdAt,
        );
      }

      if (item.data != null && item.data!['link'] != null) {
        final uri = Uri.parse(item.data!['link']);
        DeepLinkService.handleUri(uri);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await repository.markAllNotificationsRead();
      for (int i = 0; i < notifications.length; i++) {
        final item = notifications[i];
        if (!item.isRead) {
          notifications[i] = NotificationModel(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            data: item.data,
            isRead: true,
            createdAt: item.createdAt,
          );
        }
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    }
  }
}
