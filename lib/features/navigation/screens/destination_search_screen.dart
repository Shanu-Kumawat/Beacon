import 'package:beacon/core/model/recent_location.dart';
import 'package:beacon/core/model/navigation_model.dart' as custom;
import 'package:beacon/features/ar_navigation/screens/ar_navigation_screen.dart';
import 'package:beacon/features/navigation/repository/location_repository.dart';
import 'package:beacon/features/navigation/repository/place_search_repository.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beacon/features/navigation/controller/place_search_controller.dart';
import '../../voiceCommands/voiceCommands.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:beacon/seacret.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  PorcupineManager? _porcupineManager;

  // State variables
  bool _isVoiceInitialized = false;
  bool _isWakeWordActive = false;
  bool _shouldListenForWakeWord = true;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleRouteChange();
  }

  @override
  void dispose() {
    _cleanupResources();
    _searchController.dispose();
    super.dispose();
  }

  // Route handling
  void _handleRouteChange() {
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrentRoute && !_isWakeWordActive) {
      _startWakeWordDetection();
    } else if (!isCurrentRoute && _isWakeWordActive) {
      _stopWakeWordDetection();
    }
  }

  // Initialization methods
  Future<void> _initializeAll() async {
    await Future.wait([
      _initializeTTS(),
      _initializeVoiceCommand(),
      _initializePorcupine(),
    ]);
    await _startWakeWordDetection();
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en_US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _initializeVoiceCommand() async {
    if (!_isVoiceInitialized) {
      try {
        final voiceCommandNotifier = ref.read(voiceCommandProvider.notifier);
        _isVoiceInitialized = await voiceCommandNotifier.initialize();
        debugPrint('Voice command initialization status: $_isVoiceInitialized');
      } catch (e) {
        debugPrint('Voice command initialization error: $e');
        _isVoiceInitialized = false;
      }
    }
  }

  Future<void> _initializePorcupine() async {
    try {
      if (_porcupineManager != null) {
        await _porcupineManager?.delete();
        _porcupineManager = null;
      }

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        Seacret.accKey,
        ["assets/wakeup word for voice command/hey-beacon_en_android_v3_0_0.ppn"],
        _onWakeWordDetected,
        errorCallback: (error) => debugPrint('Porcupine error: ${error.message}'),
      );

      if (mounted) {
        await _startWakeWordDetection();
      }
    } catch (e) {
      debugPrint('Porcupine initialization error: $e');
    }
  }

  // Voice command handling
  void _onWakeWordDetected(int keywordIndex) async {
    debugPrint('Wake word detected with keywordIndex: $keywordIndex');
    if (mounted) {
      _handleWakeWordDetection();
    }
  }

  Future<void> _handleWakeWordDetection() async {
    if (!_shouldListenForWakeWord) return;

    await _stopWakeWordDetection();

    if (mounted) {
      await _speak('Where would you like to go?');
      await Future.delayed(const Duration(milliseconds: 1500));
      _toggleListening();
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _toggleListening() {
    final voiceState = ref.read(voiceCommandProvider);

    if (!voiceState.isListening) {
      ref.read(voiceCommandProvider.notifier).startListening(_handleVoiceCommand);
    } else {
      ref.read(voiceCommandProvider.notifier).stopListening();
      _resetWakeWordDetection();
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (command.isEmpty) return;

    try {
      setState(() => _searchController.text = command);
      ref.read(placeSearchControllerProvider.notifier).searchPlaces(command);
      await _speak('Searching for $command');
      ref.read(voiceCommandProvider.notifier).stopListening();
      await _resetWakeWordDetection();
    } catch (e) {
      debugPrint('Error processing voice command: $e');
    }
  }

  // Wake word detection control
  Future<void> _startWakeWordDetection() async {
    if (_porcupineManager != null && mounted) {
      try {
        await _porcupineManager?.start();
        setState(() => _isWakeWordActive = true);
      } catch (e) {
        debugPrint('Error starting wake word detection: $e');
      }
    }
  }

  Future<void> _stopWakeWordDetection() async {
    if (_porcupineManager != null) {
      await _porcupineManager?.stop();
      if (mounted) {
        setState(() => _isWakeWordActive = false);
      }
    }
  }

  Future<void> _resetWakeWordDetection() async {
    ref.read(voiceCommandProvider.notifier).stopListening();
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      await _startWakeWordDetection();
    }
  }

  // Cleanup
  void _cleanupResources() async {
    setState(() => _isWakeWordActive = false);
    await _stopWakeWordDetection();
    await _porcupineManager?.delete();
    _porcupineManager = null;
    flutterTts.stop();
    ref.read(voiceCommandProvider.notifier).stopListening();
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
}