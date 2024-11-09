//detection_repository.dart

import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:beacon/core/model/detection.dart';
import 'package:beacon/core/utils/image_converter.dart';

class DetectionRepository {
  final ObjectDetector _objectDetector;
  CameraDescription? _camera; // Make nullable
  bool _isProcessing = false; // Add this flag

  DetectionRepository()
      : _objectDetector = ObjectDetector(
          options: ObjectDetectorOptions(
            mode: DetectionMode.stream,
            classifyObjects: true,
            multipleObjects: true,
          ),
        );

  void setCamera(CameraDescription camera) {
    _camera = camera;
  }

  Future<List<Detection>> processImage(
    CameraImage image,
    CameraController controller,
  ) async {
    if (_camera == null) {
      print('Camera not initialized');
      return [];
    }

    if (_isProcessing) {
      return [];
    }

    try {
      _isProcessing = true;
      print('Processing image: ${image.width}x${image.height}');
      print('Image format: ${image.format.group}');
      print('Planes: ${image.planes.length}');

      final inputImage = ImageConverter.convertCameraImage(
        image,
        controller,
        _camera!,
      );

      if (inputImage == null) {
        print('Failed to convert camera image. Format: ${image.format.group}');
        return [];
      }

      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);

      return _convertDetectedObjectsToDetections(objects);
    } catch (e, stackTrace) {
      print('Error processing image: $e');
      print('Stack trace: $stackTrace');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  List<Detection> _convertDetectedObjectsToDetections(
      List<DetectedObject> objects) {
    return objects.map((object) {
      final label = object.labels.isNotEmpty
          ? object.labels.reduce(
              (curr, next) => curr.confidence > next.confidence ? curr : next)
          : null;

      return Detection(
        content: label?.text ?? 'Unknown object',
        confidence: label?.confidence ?? 0.0,
        type: DetectionType.object,
        timestamp: DateTime.now(),
        isHighPriority: label != null &&
            label.confidence > 0.8 &&
            _isHighPriorityObject(label.text),
      );
    }).toList();
  }

  bool _isHighPriorityObject(String label) {
    final highPriorityObjects = {
      'person',
      'car',
      'truck',
      'stairs',
      'door',
      'bicycle',
      'motorcycle',
      'bus',
      'obstacle',
      'wall',
    };
    return highPriorityObjects.contains(label.toLowerCase());
  }

  void dispose() {
    _objectDetector.close();
  }
}
