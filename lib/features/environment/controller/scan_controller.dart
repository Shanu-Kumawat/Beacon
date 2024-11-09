// lib/features/scan_environment/controllers/scan_controller.dart
import 'dart:io';

import 'package:beacon/core/model/detection.dart';
import 'package:beacon/core/utils/tts_manager.dart';
import 'package:beacon/features/environment/repository/detection_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

final scanControllerProvider =
    StateNotifierProvider<ScanController, ScanState>((ref) {
  return ScanController(DetectionRepository());
});

class ScanState {
  final bool isScanning;
  final bool isMuted;
  final List<Detection> recentDetections;
  final CameraController? cameraController;

  ScanState({
    this.isScanning = false,
    this.isMuted = false,
    this.recentDetections = const [],
    this.cameraController,
  });

  ScanState copyWith({
    bool? isScanning,
    bool? isMuted,
    List<Detection>? recentDetections,
    CameraController? cameraController,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      isMuted: isMuted ?? this.isMuted,
      recentDetections: recentDetections ?? this.recentDetections,
      cameraController: cameraController ?? this.cameraController,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final DetectionRepository _detectionRepository;
  final FlutterTts _flutterTts = FlutterTts();
  final _ttsManager = TextToSpeechManager();
  late final CameraController controller;

  ScanController(this._detectionRepository) : super(ScanState()) {
    _initializeTTS();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      // Set the camera in repository
      _detectionRepository.setCamera(camera);

      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      state = state.copyWith(cameraController: controller);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  void toggleScanning() async {
    if (!state.isScanning) {
      state = state.copyWith(isScanning: true);
      _speak("Scanning started");
      _startDetection();
    } else {
      state = state.copyWith(isScanning: false);
      _speak("Scanning paused");
    }
  }

  void _startDetection() async {
    final camera = state.cameraController;
    if (camera == null) return;

    camera.startImageStream((image) async {
      if (!state.isScanning) return;

      final detections = await _detectionRepository.processImage(
        image,
        controller,
      );

      if (detections.isNotEmpty) {
        state = state.copyWith(
          recentDetections:
              [...detections, ...state.recentDetections].take(10).toList(),
        );

        // Announce high priority detections with confidence
        for (final detection in detections.where((d) => d.isHighPriority)) {
          final confidencePercent =
              (detection.confidence * 100).toStringAsFixed(0);
          _speak(
              "${detection.content} detected  with $confidencePercent% confidence");
        }
      }
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void _speak(String text) {
    if (!state.isMuted) {
      _ttsManager.speak(text);
    }
  }

  void readAllDetections() {
    final detections = state.recentDetections;
    if (detections.isEmpty) {
      _speak("No recent detections");
      return;
    }

    final text = detections.map((d) => d.content).join(". ");
    _speak(text);
  }

  @override
  void dispose() {
    state.cameraController?.dispose();
    _flutterTts.stop();
    _detectionRepository.dispose();
    super.dispose();
  }
}
