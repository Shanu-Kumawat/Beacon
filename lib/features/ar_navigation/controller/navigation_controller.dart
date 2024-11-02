import 'dart:math';

import 'package:beacon/core/model/navigation_model.dart';
import 'package:beacon/features/ar_navigation/repository/navigation_repositoy.dart';
import 'package:beacon/features/navigation/repository/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, AsyncValue<NavigationState>>(
        (ref) {
  return NavigationController(ref);
});

class NavigationState {
  final NavigationRoute route;
  final int currentStepIndex;
  final double currentBearing;
  final double distanceToNextStep;
  final List<String> detectedObstacles;
  final LatLng currentLocation;

  NavigationState({
    required this.route,
    required this.currentStepIndex,
    required this.currentBearing,
    required this.distanceToNextStep,
    required this.detectedObstacles,
    required this.currentLocation,
  });
}

class NavigationController extends StateNotifier<AsyncValue<NavigationState>> {
  final Ref ref;
  final FlutterTts flutterTts = FlutterTts();
  CameraController? cameraController;
  bool isProcessingFrame = false;

  NavigationController(this.ref) : super(const AsyncValue.loading()) {
    _initializeCamera();
    //_initializeTflite();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await cameraController!.initialize();
    //cameraController!.startImageStream((image) => _processImage(image));
  }

  //Future<void> _initializeTflite() async {
  //  await Tflite.loadModel(
  //    model: "assets/model/ssd_mobilenet.tflite",
  //    labels: "assets/ssd_mobilenet.txt",
  //  );
  //}
  //
  //Future<void> _processImage(CameraImage image) async {
  //  if (isProcessingFrame) return;
  //  isProcessingFrame = true;
  //
  //  try {
  //    final recognitions = await Tflite.detectObjectOnFrame(
  //      bytesList: image.planes.map((plane) => plane.bytes).toList(),
  //      imageHeight: image.height,
  //      imageWidth: image.width,
  //    );
  //
  //    if (recognitions != null && recognitions.isNotEmpty) {
  //      final obstacles = recognitions
  //          .where((element) => element['confidenceInClass'] > 0.5)
  //          .map((e) => e['detectedClass'] as String)
  //          .toList();
  //
  //      if (obstacles.isNotEmpty) {
  //        _announceObstacles(obstacles);
  //      }
  //    }
  //  } finally {
  //    isProcessingFrame = false;
  //  }
  //}
  //
  //void _announceObstacles(List<String> obstacles) {
  //  final message = 'Warning: ${obstacles.join(", ")} detected';
  //  flutterTts.speak(message);
  //}

  Future<void> startNavigation(LatLng destination) async {
    try {
      final repository = ref.read(navigationRepositoryProvider);
      final locationRepo = ref.read(locationRepositoryProvider);

      final position = await locationRepo.getCurrentPosition();
      final start = LatLng(position.latitude, position.longitude);

      final route = await repository.getNavigation(start, destination);

      // Start compass listening
      FlutterCompass.events?.listen((CompassEvent event) {
        _updateNavigation(event.heading ?? 0);
      });

      state = AsyncValue.data(NavigationState(
        route: route,
        currentStepIndex: 0,
        currentBearing: 0,
        distanceToNextStep: route.steps[0].distance,
        detectedObstacles: [],
        currentLocation: start,
      ));
      // Announce first instruction
      _announceInstruction(route.steps[0].instruction);
    } catch (e) {
      state =
          AsyncValue.error('Error starting navigation: $e', StackTrace.current);
    }
  }

  DateTime? _lastApiCallTime;

  void _updateNavigation(double heading) {
    if (!state.hasValue) return;

    print("executed");

    final currentState = state.value!;

    // Only proceed with API call if enough time has passed since last call
    final currentTime = DateTime.now();
    if (_lastApiCallTime == null ||
        currentTime.difference(_lastApiCallTime!).inSeconds >= 2) {
      // Update the last API call time
      _lastApiCallTime = currentTime;

      print("api call");

      // Call the API to get the current position
      ref
          .read(locationRepositoryProvider)
          .getCurrentPosition()
          .then((position) {
        final currentLocation = LatLng(position.latitude, position.longitude);

        // Get current step coordinates
        final currentStep =
            currentState.route.steps[currentState.currentStepIndex];
        final nextWaypoint = currentStep.coordinates.last;

        final distanceToNext = _calculateDistance(
          currentLocation,
          nextWaypoint,
        );

        // Check if we should move to next step
        if (distanceToNext < 10 && // Within 10 meters of next step
            currentState.currentStepIndex <
                currentState.route.steps.length - 1) {
          final nextIndex = currentState.currentStepIndex + 1;
          _announceInstruction(currentState.route.steps[nextIndex].instruction);

          state = AsyncValue.data(NavigationState(
            route: currentState.route,
            currentStepIndex: nextIndex,
            currentBearing: heading,
            distanceToNextStep: distanceToNext,
            detectedObstacles: currentState.detectedObstacles,
            currentLocation: currentLocation,
          ));
        } else {
          state = AsyncValue.data(NavigationState(
            route: currentState.route,
            currentStepIndex: currentState.currentStepIndex,
            currentBearing: heading,
            distanceToNextStep: distanceToNext,
            detectedObstacles: currentState.detectedObstacles,
            currentLocation: currentLocation,
          ));
        }
      });
    } else {
      // Update the heading without calling the API
      state = AsyncValue.data(NavigationState(
        route: currentState.route,
        currentStepIndex: currentState.currentStepIndex,
        currentBearing: heading,
        distanceToNextStep: currentState.distanceToNextStep,
        detectedObstacles: currentState.detectedObstacles,
        currentLocation: currentState.currentLocation,
      ));
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Implement Haversine formula for distance calculation
    // This is a simplified version, you might want to use a geodesy package
    const R = 6371e3; // Earth's radius in meters
    final phi1 = start.latitude * pi / 180;
    final phi2 = end.latitude * pi / 180;
    final deltaPhi = (end.latitude - start.latitude) * pi / 180;
    final deltaLambda = (end.longitude - start.longitude) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  Future<void> _announceInstruction(String instruction) async {
    await flutterTts.speak(instruction);
  }

  @override
  void dispose() {
    cameraController?.dispose();
    //Tflite.close();
    super.dispose();
  }
}
