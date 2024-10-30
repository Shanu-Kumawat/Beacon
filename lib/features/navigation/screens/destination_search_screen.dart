import 'package:beacon/core/model/recent_location.dart';
import 'package:beacon/features/navigation/repository/place_search_repository.dart';
import 'package:beacon/features/navigation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beacon/features/navigation/controller/place_search_controller.dart';

class LocationSearchScreen extends ConsumerWidget {
  final TextEditingController _searchController = TextEditingController();

  LocationSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeSearchController = ref.watch(placeSearchControllerProvider);
    final recentDestinations = ref.watch(recentDestinationsProvider);

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
                ? _buildRecentDestinations(recentDestinations, context, ref)
                : _buildSearchResults(placeSearchController, context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDestinations(
    List<RecentDestination> recentDestinations,
    BuildContext context,
    WidgetRef ref,
  ) {
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
                builder: (context) => MapScreen(
                  location: destination.location,
                  name: destination.address,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(
    AsyncValue<List<PlaceSearchResult>> placeSearchController,
    BuildContext context,
    WidgetRef ref,
  ) {
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
              // Add to recent destinations
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
                  builder: (context) => MapScreen(
                    location: LatLng(result.latitude, result.longitude),
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
}
