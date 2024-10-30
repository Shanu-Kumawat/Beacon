import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Maps/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSearchScreen extends StatefulWidget {
  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OpenStreetMapService _mapService = OpenStreetMapService();
  List<RecentLocation> _recentLocations = [];
  String? _currentAddress;
  bool _showCurrentAddress = false;
  List<LocationResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLocationsJson = prefs.getStringList('recentLocations') ?? [];
    setState(() {
      _recentLocations = recentLocationsJson
          .map((json) => RecentLocation.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLocationsJson = _recentLocations
        .map((location) => jsonEncode(location.toJson()))
        .toList();
    await prefs.setStringList('recentLocations', recentLocationsJson);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final locations = await _mapService.searchLocations(
          '${position.latitude},${position.longitude}');
      if (locations.isNotEmpty) {
        setState(() {
          _currentAddress = locations.first.name;
          _showCurrentAddress = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _handleLocationClick(LocationResult location) {
    // Update visit count
    final existingLocation = _recentLocations.firstWhere(
          (recent) => recent.name == location.name,
      orElse: () => RecentLocation(
        name: location.name,
        address: location.name,
        visits: 0,
        location: location.location,
      ),
    );

    setState(() {
      if (_recentLocations.contains(existingLocation)) {
        existingLocation.visits++;
      } else {
        _recentLocations.insert(
          0,
          RecentLocation(
            name: location.name,
            address: location.name,
            visits: 1,
            location: location.location,
          ),
        );
      }
    });

    _saveRecentLocations();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Where would you like to go?'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) async {
                if (query.isEmpty) {
                  setState(() => _searchResults = []);
                  return;
                }
                final results = await _mapService.searchLocations(query);
                setState(() => _searchResults = results);
              },
              decoration: InputDecoration(
                hintText: 'Search destination or address',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.mic),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    title: Text(result.name),
                    onTap: () => _handleLocationClick(result),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.location_on, color: Colors.white),
                    ),
                    title: Text('Use Current Location'),
                    onTap: _getCurrentLocation,
                  ),
                  if (_showCurrentAddress)
                    ListTile(
                      title: Text(_currentAddress ?? ''),
                      onTap: () {
                        // Navigate to map with current location
                      },
                    ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Recent Destinations'),
                  ),
                  ..._recentLocations.map((location) => ListTile(
                    title: Text(location.name),
                    subtitle: Text(location.address),
                    trailing: Text('${location.visits} times'),
                    onTap: () => _handleLocationClick(
                      LocationResult(
                        name: location.name,
                        location: location.location,
                        placeId: '',
                      ),
                    ),
                  )),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.star),
                    title: Text('Favorite Places'),
                  ),
                  // Add your favorite places here
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class RecentLocation {
  final String name;
  final String address;
  int visits;
  final LatLng location;

  RecentLocation({
    required this.name,
    required this.address,
    required this.visits,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'visits': visits,
      'lat': location.latitude,
      'lng': location.longitude,
    };
  }

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      name: json['name'],
      address: json['address'],
      visits: json['visits'],
      location: LatLng(json['lat'], json['lng']),
    );
  }
}
