import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/location_controller.dart';
import '../controller/place_search_controller.dart';

class DestinationSearchScreen extends ConsumerWidget {
  const DestinationSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationController = ref.watch(locationControllerProvider);
    final searchResults = ref.watch(placeSearchControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Where would you like to go?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBox(ref),
              const SizedBox(height: 16),
              searchResults.when(
                data: (results) {
                  if (results.isEmpty) {
                    return _buildDefaultContent(ref, locationController);
                  }
                  return Column(
                    children: results.map((result) => Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on, color: AppTheme.primary),
                          title: Text(
                            result.address,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${result.distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, result);
                          },
                        ),
                        const Divider(color: AppTheme.divider),
                      ],
                    )).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildDefaultContent(WidgetRef ref, AsyncValue<String?> locationController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => ref.read(locationControllerProvider.notifier).getCurrentLocation(),
          child: _buildCurrentLocationButton(locationController),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(Icons.access_time, 'Recent Destinations'),
        const SizedBox(height: 16),
        _buildRecentDestination('Home', '123 Main Street', '5 times'),
        const Divider(color: AppTheme.divider),
        _buildRecentDestination('Work', '456 Office Ave', '3 times'),
        const Divider(color: AppTheme.divider),
        _buildRecentDestination('Central Park', 'Park Avenue', '2 times'),
        const Divider(color: AppTheme.divider),
        const SizedBox(height: 24),
        _buildSectionTitle(Icons.star_border, 'Favorite Places'),
        const SizedBox(height: 16),
        _buildFavoritePlace('Grocery Store', '789 Market St', 'Shopping'),
        const Divider(color: AppTheme.divider),
        _buildFavoritePlace('Doctor\'s Office', '321 Medical Rd', 'Healthcare'),
      ],
    );
  }

  Widget _buildSearchBox(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search destination or address',
          hintStyle: TextStyle(color: AppTheme.textHint),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: Icon(Icons.mic, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          ref.read(placeSearchControllerProvider.notifier).searchPlaces(value);
        },
      ),
    );
  }

  Widget _buildCurrentLocationButton(AsyncValue<String?> locationController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Use Current Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          locationController.when(
            data: (address) => address != null
                ? Text(
              address,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            )
                : const SizedBox.shrink(),
            loading: () => const Text('Getting location...',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            error: (err, stack) => Text('$err',
                style: const TextStyle(fontSize: 14, color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            times,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}