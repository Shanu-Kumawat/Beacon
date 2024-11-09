// lib/features/scan_environment/utils/distance_calculator.dart
import 'dart:math';
import 'package:flutter/material.dart';

class DistanceCalculator {
  static const double FOCAL_LENGTH = 1000.0; // pixels
  static const double AVERAGE_OBJECT_HEIGHT =
      1.7; // meters (average human height as reference)

  static String calculateDistance(Rect boundingBox, Size imageSize) {
    // Using the pinhole camera model for distance estimation
    final double objectHeightInPixels = boundingBox.height;
    final double distanceInMeters =
        (FOCAL_LENGTH * AVERAGE_OBJECT_HEIGHT) / objectHeightInPixels;

    if (distanceInMeters < 1) {
      return '${(distanceInMeters * 100).toStringAsFixed(0)} cm';
    } else {
      return '${distanceInMeters.toStringAsFixed(1)} m';
    }
  }

  static String getRelativePosition(Rect boundingBox, Size imageSize) {
    final double centerX = boundingBox.center.dx;
    final double imageCenter = imageSize.width / 2;

    if ((centerX - imageCenter).abs() < imageSize.width * 0.2) {
      return 'directly ahead';
    } else if (centerX < imageCenter) {
      return 'to the left';
    } else {
      return 'to the right';
    }
  }
}
