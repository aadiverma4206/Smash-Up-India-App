import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cctv_controller.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';

class CctvListView extends GetView<CctvController> {
  const CctvListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV Cameras & Live Stream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Live CCTV Stream',
            onPressed: () => Get.toNamed(Routes.cctvLive),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Camera',
            onPressed: () => Get.toNamed('/manager/cctv/add'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cameras.isEmpty) {
          return const AppLoader(message: 'Loading CCTV cameras...');
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prominent Live CCTV Hero Card Banner for Admin & Managers
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              color: const Color(0xFF1E1E1E),
              child: InkWell(
                onTap: () => Get.toNamed(Routes.cctvLive),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Live CCTV Feed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '● LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '4 Dahua Camera Channels (Pitch 1 & 2)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Configured Camera List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            if (controller.cameras.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.videocam_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No Static Cameras Configured',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Live CCTV feed is available above via Dahua XVR channels.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(controller.cameras.length, (index) {
                final cam = controller.cameras[index];
                final isOnline =
                    cam.status == 'ONLINE' && cam.healthStatus == 'ONLINE';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isOnline ? AppColors.primary : AppColors.error,
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.videocam,
                                color:
                                    isOnline ? AppColors.primary : AppColors.error,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cam.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cam.healthStatus,
                                  style: TextStyle(
                                    color: isOnline
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Court: ${cam.courtName ?? "Unassigned"} • Type: ${cam.cameraType}',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 13),
                          ),
                          Text(
                            'IP: ${cam.ipAddress ?? "192.168.1.2"}',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => controller.testCamera(cam.id),
                                icon: const Icon(Icons.network_check_rounded,
                                    size: 16),
                                label: const Text('Test Connection',
                                    style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => Get.toNamed(Routes.cctvLive),
                                icon: const Icon(Icons.play_circle_fill,
                                    size: 16),
                                label: const Text('Watch Live',
                                    style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}
