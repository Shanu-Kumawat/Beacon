import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/location_repository.dart';

final locationControllerProvider =
    StateNotifierProvider<LocationController, AsyncValue<String?>>((ref) {
  return LocationController(ref);
});

class LocationController extends StateNotifier<AsyncValue<String?>> {
  final Ref ref;

  LocationController(this.ref) : super(const AsyncValue.data(null));

  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(locationRepositoryProvider);
      final hasPermission = await repository.checkLocationPermission();
      if (!hasPermission) {
        state = AsyncValue.error(
            'Location permissions denied.', StackTrace.current);
        return;
      }
      final position = await repository.getCurrentPosition();
      final address = await repository.getAddressFromPosition(position);
      state = AsyncValue.data(address);
    } catch (e) {
      state =
          AsyncValue.error('Error getting location: $e', StackTrace.current);
    }
  }
}
