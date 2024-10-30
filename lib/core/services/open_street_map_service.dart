import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationResult {
  final String name;
  final LatLng location;
  final String placeId;

  LocationResult({
    required this.name,
    required this.location,
    required this.placeId,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      name: json['display_name'],
      location: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      placeId: json['place_id'].toString(),
    );
  }
}

class OpenStreetMapService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationResult>> searchLocations(String query) async {
    final Uri url = Uri.parse('$baseUrl?q=$query&format=json&limit=10');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'YourAppName/1.0', // Replace with your app's name
      }).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<LocationResult> locations = data.map((place) => LocationResult.fromJson(place)).toList();
        return locations;
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching locations: $e');
    }
  }
}
