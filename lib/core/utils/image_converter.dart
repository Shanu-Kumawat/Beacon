import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ImageConverter {
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static InputImage? convertCameraImage(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    if (Platform.isAndroid) {
      return _convertAndroid(image, controller, camera);
    } else if (Platform.isIOS) {
      return _convertIOS(image, controller, camera);
    }
    return null;
  }

  static InputImage? _convertAndroid(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    try {
      // Get rotation values
      final sensorOrientation = camera.sensorOrientation;
      final rotationCompensation = 
          _orientations[controller.value.deviceOrientation] ?? 0;
      
      final rotation = InputImageRotationValue.fromRawValue(
        (sensorOrientation + rotationCompensation) % 360
      );
      if (rotation == null) return null;

      // Convert YUV420 to NV21 since ML Kit works better with NV21
      final convertedBytes = _yuv420toNV21(image);
      
      return InputImage.fromBytes(
        bytes: convertedBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } catch (e, stackTrace) {
      print('Error converting Android image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Uint8List _yuv420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    // Calculate total size needed for NV21 format
    final int size = width * height + ((width + 1) ~/ 2) * ((height + 1) ~/ 2) * 2;
    final Uint8List nv21Data = Uint8List(size);

    // Copy Y plane as-is
    int index = 0;
    final yPlane = image.planes[0];
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel!;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x * yPixelStride;
        nv21Data[index++] = yPlane.bytes[yIndex];
      }
    }

    // Copy UV planes
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvHeight = (height + 1) ~/ 2;
    final uvWidth = (width + 1) ~/ 2;
    
    for (int y = 0; y < uvHeight; y++) {
      for (int x = 0; x < uvWidth; x++) {
        final int uvIndex = y * uvRowStride + x * uvPixelStride;
        nv21Data[index++] = vPlane.bytes[uvIndex]; // V plane first in NV21
        nv21Data[index++] = uPlane.bytes[uvIndex]; // U plane second
      }
    }

    return nv21Data;
  }

  static InputImage? _convertIOS(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation
      );
      if (rotation == null) return null;

      if (image.format.group != ImageFormatGroup.bgra8888) {
        print('Unsupported iOS format: ${image.format.group}');
        return null;
      }

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting iOS image: $e');
      return null;
    }
  }
}
