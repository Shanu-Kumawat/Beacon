import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final placeSearchRepositoryProvider = Provider((ref) => PlaceSearchRepository());

class PlaceSearchRepository {
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      if (query.isEmpty) return [];

      // Get locations from the search query
      List<Location> locations = await locationFromAddress(query);

      // Convert locations to addresses for more detailed information
      List<PlaceSearchResult> results = await Future.wait(
        locations.map((location) async {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            return PlaceSearchResult(
              address: _formatAddress(place),
              latitude: location.latitude,
              longitude: location.longitude,
              distance: await _calculateDistanceFromCurrent(
                location.latitude,
                location.longitude,
              ),
            );
          }

          return PlaceSearchResult(
            address: 'Unknown location',
            latitude: location.latitude,
            longitude: location.longitude,
            distance: await _calculateDistanceFromCurrent(
              location.latitude,
              location.longitude,
            ),
          );
        }),
      );

      // Sort results by distance
      results.sort((a, b) => a.distance.compareTo(b.distance));

      return results;
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      if (place.street?.isNotEmpty == true) place.street!,
      if (place.subLocality?.isNotEmpty == true) place.subLocality!,
      if (place.locality?.isNotEmpty == true) place.locality!,
      if (place.postalCode?.isNotEmpty == true) place.postalCode!,
    ];

    return addressParts.join(', ');
  }

  Future<double> _calculateDistanceFromCurrent(
      double targetLat,
      double targetLng,
      ) async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );

      return distanceInMeters / 1000; // Convert to kilometers
    } catch (e) {
      return double.infinity; // Return infinity if unable to calculate distance
    }
  }
}

class PlaceSearchResult {
  final String address;
  final double latitude;
  final double longitude;
  final double distance;

  PlaceSearchResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
}