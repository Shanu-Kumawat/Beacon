class NavigationStep {
  final String instruction;
  final double distance;
  final double duration;
  final int type;
  final String name;
  final List<int> wayPoints;
  final List<LatLng> coordinates;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.type,
    required this.name,
    required this.wayPoints,
    required this.coordinates,
  });

  factory NavigationStep.fromJson(
      Map<String, dynamic> json, List<List<double>> allCoordinates) {
    final wayPoints = (json['way_points'] as List).cast<int>();
    // Extract coordinates for this step using way_points
    final stepCoordinates = allCoordinates
        .sublist(wayPoints[0], wayPoints[1] + 1)
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();

    return NavigationStep(
      instruction: json['instruction'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      type: json['type'] as int,
      name: json['name'] as String,
      wayPoints: wayPoints,
      coordinates: stepCoordinates,
    );
  }
}

class NavigationRoute {
  final List<NavigationStep> steps;
  final double totalDistance;
  final double totalDuration;
  final List<LatLng> allCoordinates;

  NavigationRoute({
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.allCoordinates,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    final feature = json['features'][0];
    final geometry = feature['geometry'];
    final properties = feature['properties'];
    final segment = properties['segments'][0];

    // Convert all coordinates first
    final allCoords = (geometry['coordinates'] as List)
        .map((coord) => (coord as List).cast<double>())
        .toList();

    // Convert coordinates to LatLng objects
    final allLatLngs =
        allCoords.map((coord) => LatLng(coord[1], coord[0])).toList();

    // Create steps with corresponding coordinates
    final steps = (segment['steps'] as List)
        .map((step) => NavigationStep.fromJson(step, allCoords))
        .toList();

    return NavigationRoute(
      steps: steps,
      totalDistance: segment['distance'].toDouble(),
      totalDuration: segment['duration'].toDouble(),
      allCoordinates: allLatLngs,
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
