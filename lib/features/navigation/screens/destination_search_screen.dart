import 'package:beacon/core/model/recent_location.dart';
import 'package:beacon/core/model/navigation_model.dart' as custom;
import 'package:beacon/features/ar_navigation/screens/ar_navigation_screen.dart';
import 'package:beacon/features/navigation/repository/location_repository.dart';
import 'package:beacon/features/navigation/repository/place_search_repository.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beacon/features/navigation/controller/place_search_controller.dart';
import '../../../voiceCommands.dart';


class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize voice commands when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceCommandProvider.notifier).initialize();
    });
  }

  void _handleVoiceCommand(String command) {
    _searchController.text = command;
    ref.read(placeSearchControllerProvider.notifier).searchPlaces(command);
  }

  void _toggleListening() {
    final voiceState = ref.read(voiceCommandProvider);
    if (!voiceState.isListening) {
      ref.read(voiceCommandProvider.notifier).startListening(_handleVoiceCommand);
    } else {
      ref.read(voiceCommandProvider.notifier).stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeSearchController = ref.watch(placeSearchControllerProvider);
    final recentDestinations = ref.watch(recentDestinationsProvider);
    final voiceState = ref.watch(voiceCommandProvider);

    ref.watch(locationRepositoryProvider).checkLocationPermission();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where would you like to go?'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref
                    .read(placeSearchControllerProvider.notifier)
                    .searchPlaces(query);
              },
              decoration: InputDecoration(
                hintText: 'Search destination or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(
                    voiceState.isListening ? Icons.mic : Icons.mic_none,
                    color: voiceState.isListening ? Colors.blue : null,
                  ),
                  onPressed: voiceState.isInitialized ? _toggleListening : null,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searchController.text.isEmpty && recentDestinations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Destinations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(recentDestinationsProvider.notifier)
                          .clearRecentDestinations();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildRecentDestinations(recentDestinations)
                : _buildSearchResults(placeSearchController),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDestinations(List<RecentDestination> recentDestinations) {
    if (recentDestinations.isEmpty) {
      return const Center(
        child: Text('No recent destinations'),
      );
    }

    return ListView.builder(
      itemCount: recentDestinations.length,
      itemBuilder: (context, index) {
        final destination = recentDestinations[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(destination.address),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArNavigationScreen(
                  location: custom.LatLng(destination.location.latitude,
                      destination.location.longitude),
                  name: destination.address,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(AsyncValue<List<PlaceSearchResult>> placeSearchController) {
    return placeSearchController.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      data: (results) => ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(result.address),
            onTap: () {
              ref
                  .read(recentDestinationsProvider.notifier)
                  .addRecentDestination(
                RecentDestination(
                  address: result.address,
                  location: LatLng(result.latitude, result.longitude),
                  timestamp: DateTime.now(),
                ),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArNavigationScreen(
                    location: custom.LatLng(result.latitude, result.longitude),
                    name: result.address,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}