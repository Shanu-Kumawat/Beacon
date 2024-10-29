import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}
class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  String? _currentAddress;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  void _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Location services enabled: $serviceEnabled');

    permission = await Geolocator.checkPermission();
    debugPrint('Initial location permission status: $permission');
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable the services')));
        return false;
      }

      permission = await Geolocator.checkPermission();
      debugPrint('Permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Permission status after request: $permission');

        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable in settings.')));
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error in _handleLocationPermission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error handling location permission: $e')));
      return false;
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      final hasPermission = await _handleLocationPermission();
      debugPrint('Has permission: $hasPermission');

      if (!hasPermission) return;

      setState(() {
        _currentAddress = 'Getting location...';
      });

      debugPrint('Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      debugPrint('Position received: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
        _currentAddress = 'Getting address...';
      });

      await _getAddressFromLatLng();
    } catch (e) {
      debugPrint('Error getting current position: $e');
      setState(() {
        _currentAddress = 'Error getting location';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      if (_currentPosition != null) {
        debugPrint('Getting address for position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        Placemark place = placemarks[0];
        debugPrint('Placemark received: $place');

        setState(() {
          _currentAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _currentAddress = 'Error getting address';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Where would you like to go?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search destination or address',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              InkWell(
                onTap: _getCurrentPosition,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Use Current Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_currentAddress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _currentAddress!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Destinations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Destinations List
              _buildRecentDestination('Home', '123 Main Street', '5 times'),
              const Divider(),
              _buildRecentDestination('Work', '456 Office Ave', '3 times'),
              const Divider(),
              _buildRecentDestination('Central Park', 'Park Avenue', '2 times'),
              const Divider(),

              const SizedBox(height: 24),

              // Favorite Places Section
              Row(
                children: [
                  const Icon(Icons.star_border, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Favorite Places',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Favorite Places List
              _buildFavoritePlace('Grocery Store', '789 Market St', 'Shopping'),
              const Divider(),
              _buildFavoritePlace('Doctor\'s Office', '321 Medical Rd', 'Healthcare'),

            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRecentDestination(String title, String address, String times) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            times,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFavoritePlace(String title, String address, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
