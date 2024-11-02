import 'package:beacon/core/model/navigation_model.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ArPathPainter extends CustomPainter {
  final NavigationRoute route;
  final double bearing;
  final LatLng currentLocation;
  final double screenWidth;
  final double screenHeight;

  ArPathPainter({
    required this.route,
    required this.bearing,
    required this.currentLocation,
    required this.screenWidth,
    required this.screenHeight,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final screenPoints = _projectPathToScreen();

    if (screenPoints.length >= 2) {
      final path = Path();
      path.moveTo(screenPoints[0].dx, screenPoints[0].dy);

      for (int i = 1; i < screenPoints.length; i++) {
        path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  List<Offset> _projectPathToScreen() {
    List<Offset> screenPoints = [];
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;

    for (var point in route.allCoordinates) {
      // Calculate relative position to current location
      final dx = _calculateDistance(currentLocation.longitude,
              currentLocation.latitude, point.longitude, point.latitude) *
          math.cos(_calculateBearing(currentLocation, point));
      final dy = _calculateDistance(currentLocation.longitude,
              currentLocation.latitude, point.longitude, point.latitude) *
          math.sin(_calculateBearing(currentLocation, point));

      // Apply rotation based on device bearing
      final rotatedX = dx * math.cos(bearing) - dy * math.sin(bearing);
      final rotatedY = dx * math.sin(bearing) + dy * math.cos(bearing);

      // Project 3D coordinates to screen space
      // Using a simple perspective projection
      const focalLength =
          800.0; // Adjust this value to change perspective effect
      final scale = 1;

      final screenX = centerX + rotatedX * scale;
      final screenY = centerY - rotatedY * scale;

      screenPoints.add(Offset(screenX, screenY));
    }

    return screenPoints;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final dLon = (end.longitude - start.longitude) * math.pi / 180.0;
    final startLat = start.latitude * math.pi / 180.0;
    final endLat = end.latitude * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLon);

    return math.atan2(y, x);
  }

  double _calculateDistance(
      double lon1, double lat1, double lon2, double lat2) {
    const R = 6371e3; // Earth's radius in meters
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  @override
  bool shouldRepaint(ArPathPainter oldDelegate) =>
      bearing != oldDelegate.bearing ||
      currentLocation != oldDelegate.currentLocation ||
      route.allCoordinates != oldDelegate.route.allCoordinates;
}

// Update the NavigationState class to include all path points
class NavigationState {
  final List<NavigationStep> steps;
  final int currentStepIndex;
  final double currentBearing;
  final double distanceToNextStep;
  final List<String> detectedObstacles;
  final List<LatLng> fullPath;
  final LatLng currentLocation;

  NavigationState({
    required this.steps,
    required this.currentStepIndex,
    required this.currentBearing,
    required this.distanceToNextStep,
    required this.detectedObstacles,
    required this.fullPath,
    required this.currentLocation,
  });
}
