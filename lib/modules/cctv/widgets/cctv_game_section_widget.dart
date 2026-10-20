import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cctv_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../app/theme/app_colors.dart';

class CctvGameSectionWidget extends StatefulWidget {
  final String gameId;
  final String? gameTitle;

  const CctvGameSectionWidget({
    super.key,
    required this.gameId,
    this.gameTitle,
  });

  @override
  State<CctvGameSectionWidget> createState() => _CctvGameSectionWidgetState();
}

class _CctvGameSectionWidgetState extends State<CctvGameSectionWidget> {
  late final CctvController controller;
  int _selectedChannel = 1;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CctvController>()) {
      controller = Get.find<CctvController>();
    } else {
      controller = Get.put(CctvController());
    }
    controller.fetchGameRecording(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rec = controller.currentRecording.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (rec == null ||
          rec.recordingStatus == 'NONE' ||
          rec.recordingStatus == 'FAILED') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'CCTV Match Recording',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'READY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Record full match footage directly from the court CCTV camera for player highlights and history.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Select Camera: ',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedChannel,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                          value: 1, child: Text('Camera 1 (Main Pitch)')),
                      DropdownMenuItem(
                          value: 2, child: Text('Camera 2 (Sideline)')),
                      DropdownMenuItem(
                          value: 3, child: Text('Camera 3 (Court 2 Main)')),
                      DropdownMenuItem(
                          value: 4, child: Text('Camera 4 (Court 2 Goal)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedChannel = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.startRecordingForGame(
                            widget.gameId,
                            channel: _selectedChannel,
                          ),
                  icon: const Icon(Icons.fiber_manual_record_rounded,
                      color: Colors.redAccent, size: 16),
                  label: Text(
                    controller.isLoading.value
                        ? 'Starting FFmpeg...'
                        : 'Start CCTV Match Recording',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final isRecording = rec.recordingStatus == 'RECORDING' ||
          rec.recordingStatus == 'STARTING';
      final isPostMatch = rec.recordingStatus == 'POST_MATCH';
      final isCompleted = rec.recordingStatus == 'COMPLETED' ||
          rec.recordingStatus == 'STOPPED_MANUALLY';
      final remainingSecs = controller.remainingCountdownSeconds.value;
      final minutes = (remainingSecs / 60).floor();
      final seconds = remainingSecs % 60;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecording
                ? Colors.redAccent.withValues(alpha: 0.6)
                : (isPostMatch
                    ? AppColors.secondary
                    : Colors.green.withValues(alpha: 0.5)),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: isRecording
                      ? Colors.redAccent
                      : (isPostMatch ? AppColors.secondary : Colors.green),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CCTV Match Recording Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isRecording
                            ? Colors.redAccent
                            : (isPostMatch
                                ? AppColors.secondary
                                : Colors.green))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRecording
                          ? Colors.redAccent
                          : (isPostMatch ? AppColors.secondary : Colors.green),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRecording) ...[
                        const Icon(Icons.fiber_manual_record,
                            color: Colors.redAccent, size: 10),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        rec.recordingStatus,
                        style: TextStyle(
                          color: isRecording
                              ? Colors.redAccent
                              : (isPostMatch
                                  ? AppColors.secondary
                                  : Colors.green),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isRecording) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.radio_button_checked_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Continuous FFmpeg MP4 recording is actively capturing court footage.',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmStopRecording(context, rec.id),
                  icon: const Icon(Icons.stop_rounded, color: Colors.white),
                  label: const Text('STOP RECORDING NOW',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (isPostMatch) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏰ Post-Match Recording Active (+15 min deadline)',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto-stop visual countdown: ${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'STOP RECORDING NOW',
                      onPressed: () => _confirmStopRecording(context, rec.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.add_alarm, color: AppColors.secondary),
                    tooltip: 'Extend +15m',
                    onPressed: () => controller.extendRecording(rec.id, 15),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Match recording finalized and ready for mobile streaming & download.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed('/videos/player', arguments: {
                      'videoUrl': '/api/videos/match_${widget.gameId}.mp4',
                      'title': widget.gameTitle ?? 'Match CCTV Recording',
                    });
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white),
                  label: const Text('Watch Recorded Match Video',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  void _confirmStopRecording(BuildContext context, String recordingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop CCTV Recording Now?'),
        content: const Text(
          'This will gracefully stop FFmpeg RTSP stream capture, finalize the MP4 file, and save it to match history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.stopRecordingNow(recordingId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Stop'),
          ),
        ],
      ),
    );
  }
}
