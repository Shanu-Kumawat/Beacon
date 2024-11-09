// lib/features/scan_environment/screens/scan_environment_screen.dart
import 'package:beacon/features/environment/controller/scan_controller.dart';
import 'package:beacon/features/environment/widgets/detection_list_widget.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanEnvironmentScreen extends ConsumerWidget {
  const ScanEnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);
    final controller = ref.watch(scanControllerProvider.notifier);

    return Scaffold(
      body: state.cameraController == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: CameraPreview(state.cameraController!),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Status Bar
                      Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.isScanning
                                  ? 'Actively Scanning'
                                  : 'Scanning Paused',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                state.isMuted
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: controller.toggleMute,
                            ),
                          ],
                        ),
                      ),

                      // Detection List
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DetectionListWidget(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Control Buttons
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: controller.toggleScanning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              state.isScanning ? Colors.red : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(state.isScanning
                                ? Icons.stop
                                : Icons.play_arrow),
                            const SizedBox(width: 8),
                            Text(
                              state.isScanning
                                  ? 'Stop Scanning'
                                  : 'Start Scanning',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: controller.readAllDetections,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up),
                            SizedBox(width: 8),
                            Text('Read All Detections',
                                style: TextStyle(fontSize: 18)),
                          ],
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
