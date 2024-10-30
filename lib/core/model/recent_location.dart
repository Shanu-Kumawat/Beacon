import 'package:latlong2/latlong.dart';

class RecentDestination {
  final String address;
  final LatLng location;
  final DateTime timestamp;

  RecentDestination({
    required this.address,
    required this.location,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentDestination.fromJson(Map<String, dynamic> json) {
    return RecentDestination(
      address: json['address'],
      location: LatLng(json['latitude'], json['longitude']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
