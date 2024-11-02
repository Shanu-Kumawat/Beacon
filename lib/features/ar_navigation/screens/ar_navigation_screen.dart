import 'package:beacon/features/ar_navigation/screens/ar_screen_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:beacon/core/model/navigation_model.dart';
import 'package:beacon/features/ar_navigation/controller/navigation_controller.dart';
import 'package:camera/camera.dart';

class ArNavigationScreen extends ConsumerStatefulWidget {
  final LatLng location;
  final String name;
  const ArNavigationScreen({
    super.key,
    required this.location,
    required this.name,
  });

  @override
  _ArNavigationScreenState createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen> {
  Size? screenSize;

  @override
  void initState() {
    super.initState();
    ref
        .read(navigationControllerProvider.notifier)
        .startNavigation(widget.location);
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final navigationState = ref.watch(navigationControllerProvider);
          final controller = ref.watch(navigationControllerProvider.notifier);

          return navigationState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (state) => Stack(
              children: [
                // Camera Preview
                if (controller.cameraController?.value.isInitialized ?? false)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller
                            .cameraController!.value.previewSize!.height,
                        height: controller
                            .cameraController!.value.previewSize!.width,
                        child: CameraPreview(controller.cameraController!),
                      ),
                    ),
                  ),

                // Path painter
                CustomPaint(
                  painter: ArPathPainter(
                    route: state.route,
                    bearing: state.currentBearing * math.pi / 180,
                    currentLocation: state.currentLocation,
                    screenWidth: screenSize?.width ?? 0,
                    screenHeight: screenSize?.height ?? 0,
                  ),
                  size: Size(screenSize?.width ?? 0, screenSize?.height ?? 0),
                ),

                // Navigation instructions
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.route.steps[state.currentStepIndex].instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Distance: ${state.distanceToNextStep.toStringAsFixed(0)}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
