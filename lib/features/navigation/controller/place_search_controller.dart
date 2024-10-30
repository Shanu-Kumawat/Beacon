import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../repository/place_search_repository.dart';

final placeSearchControllerProvider = StateNotifierProvider<PlaceSearchController,
    AsyncValue<List<PlaceSearchResult>>>((ref) {
  return PlaceSearchController(ref);
});

class PlaceSearchController extends StateNotifier<AsyncValue<List<PlaceSearchResult>>> {
  final Ref ref;
  Timer? _debounceTimer;

  PlaceSearchController(this.ref) : super(const AsyncValue.data([]));

  Future<void> searchPlaces(String query) async {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // If query is empty, reset state
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();

      try {
        final repository = ref.read(placeSearchRepositoryProvider);
        final results = await repository.searchPlaces(query);
        state = AsyncValue.data(results);
      } catch (e, stackTrace) {
        state = AsyncValue.error('Error searching places: $e', stackTrace);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}