// lib/features/scan_environment/widgets/detection_list_widget.dart
import 'package:beacon/core/model/detection.dart';
import 'package:beacon/features/environment/controller/scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetectionListWidget extends ConsumerWidget {
  const DetectionListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detections = ref.watch(
      scanControllerProvider.select((state) => state.recentDetections),
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: detections.length,
        itemBuilder: (context, index) {
          final detection = detections[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: detection.isHighPriority
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForType(detection.type),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.content,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(DetectionType type) {
    switch (type) {
      case DetectionType.object:
        return Icons.camera_alt;
      case DetectionType.text:
        return Icons.text_fields;
      case DetectionType.hazard:
        return Icons.warning;
    }
  }
}
