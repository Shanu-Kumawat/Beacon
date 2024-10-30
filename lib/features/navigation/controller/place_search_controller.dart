import 'dart:async';
import 'dart:convert';
import 'package:beacon/core/model/recent_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/place_search_repository.dart';

final recentDestinationsProvider =
    StateNotifierProvider<RecentDestinationsNotifier, List<RecentDestination>>(
        (ref) {
  return RecentDestinationsNotifier();
});

class RecentDestinationsNotifier
    extends StateNotifier<List<RecentDestination>> {
  RecentDestinationsNotifier() : super([]) {
    _loadRecentDestinations();
  }

  static const String _prefsKey = 'recent_destinations';
  static const int _maxRecents = 5;

  Future<void> _loadRecentDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getStringList(_prefsKey) ?? [];
    state = recentJson
        .map((json) => RecentDestination.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addRecentDestination(RecentDestination destination) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists
    state = state.where((item) => item.address != destination.address).toList();

    // Add new destination at the beginning
    state = [destination, ...state.take(_maxRecents - 1)].toList();

    // Save to SharedPreferences
    final jsonList = state.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  Future<void> clearRecentDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = [];
  }
}

final placeSearchControllerProvider = StateNotifierProvider<
    PlaceSearchController, AsyncValue<List<PlaceSearchResult>>>((ref) {
  return PlaceSearchController(ref);
});

class PlaceSearchController
    extends StateNotifier<AsyncValue<List<PlaceSearchResult>>> {
  final Ref ref;
  Timer? _debounceTimer;

  PlaceSearchController(this.ref) : super(const AsyncValue.data([]));

  Future<void> searchPlaces(String query) async {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();
      try {
        final repository = ref.read(placeSearchRepositoryProvider);
        final results = await repository.searchPlaces(query);
        if (results.isEmpty) {
          state =
              const AsyncValue.error('Location not found', StackTrace.empty);
        } else {
          state = AsyncValue.data(results);
        }
      } catch (e) {
        state =
            AsyncValue.error('Error searching places: $e', StackTrace.current);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
