import 'package:beacon/core/model/navigation_model.dart';
import 'package:beacon/seacret.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationRepositoryProvider = Provider((ref) => NavigationRepository());

class NavigationRepository {
  final Dio _dio = Dio();
  final String _apiKey = Seacret.orsKey; // Replace with your API key

  Future<NavigationRoute> getNavigation(
      LatLng start, LatLng destination) async {
    try {
      final response = await _dio.get(
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${destination.longitude},${destination.latitude}");

      print("start ${response.data} end ");

      return NavigationRoute.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get navigation steps: $e');
    }
  }
}
