import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

final placeSearchRepositoryProvider =
    Provider((ref) => PlaceSearchRepository());

class PlaceSearchRepository {
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      // Get locations from the address query
      List<Location> locations = await locationFromAddress(
        query,
      );

      List<PlaceSearchResult> results = [];

      // For each location, get all nearby placemarks
      for (var location in locations) {
        try {
          // Get multiple placemarks for each location
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          // Add each unique placemark as a result
          for (var placemark in placemarks) {
            String formattedAddress = _formatAddress(placemark);

            // Only add if it's a meaningful address
            if (formattedAddress.isNotEmpty) {
              results.add(
                PlaceSearchResult(
                  address: formattedAddress,
                  latitude: location.latitude,
                  longitude: location.longitude,
                  placemark:
                      placemark, // Added for additional details if needed
                ),
              );
            }
          }
        } catch (e) {
          print(
              'Error getting placemarks for location ${location.latitude},${location.longitude}: $e');
          // Continue to next location even if this one fails
          continue;
        }
      }

      // Remove duplicates based on address
      return _removeDuplicates(results);
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      if (place.street?.isNotEmpty == true) place.street!,
      if (place.subLocality?.isNotEmpty == true) place.subLocality!,
      if (place.locality?.isNotEmpty == true) place.locality!,
      if (place.administrativeArea?.isNotEmpty == true)
        place.administrativeArea!,
      if (place.postalCode?.isNotEmpty == true) place.postalCode!,
      if (place.country?.isNotEmpty == true) place.country!,
    ];
    return addressParts.where((part) => part.isNotEmpty).join(', ');
  }

  List<PlaceSearchResult> _removeDuplicates(List<PlaceSearchResult> results) {
    final uniqueAddresses = <String>{};
    return results.where((result) {
      final isUnique = uniqueAddresses.add(result.address);
      return isUnique;
    }).toList();
  }
}

class PlaceSearchResult {
  final String address;
  final double latitude;
  final double longitude;
  final Placemark placemark; // Added to store full placemark data

  PlaceSearchResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placemark,
  });

  @override
  String toString() {
    return 'PlaceSearchResult(address: $address, lat: $latitude, lng: $longitude)';
  }
}

