import 'package:beacon/core/common/custom_icon_button.dart';
import 'package:beacon/features/Emergency/screens/emergency.dart';
import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:beacon/features/environment/screens/scan_environment_screen.dart';
import 'package:beacon/features/navigation/screens/destination_search_screen.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../voiceCommands.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class HomeScreen extends ConsumerStatefulWidget {
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  final FlutterTts flutterTts = FlutterTts();
  PorcupineManager? _porcupineManager;
  bool _isVoiceInitialized = false;
  bool _isWakeWordActive = false;
  bool _isHomeScreenActive = false; // Initialize to false by default

  @override
  void initState() {
    super.initState();
    setState(() => _isHomeScreenActive = true); // Set to true when screen initializes
    _initializeAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() async {
    setState(() {
      _isWakeWordActive = false;
      _isHomeScreenActive = false;
    });
    await _stopWakeWordDetection(); // Ensure wake word detection is stopped
    await _porcupineManager?.delete();
    _porcupineManager = null;
    flutterTts.stop();
    ref.read(voiceCommandProvider.notifier).stopListening();
  }

  @override
  void didPush() {
    setState(() => _isHomeScreenActive = true);
    _startWakeWordDetection();
  }

  @override
  void didPopNext() {
    setState(() => _isHomeScreenActive = true);
    _startWakeWordDetection();
  }

  @override
  void didPop() {
    setState(() => _isHomeScreenActive = false);
    _stopWakeWordDetection();
  }

  @override
  void didPushNext() {
    setState(() => _isHomeScreenActive = false);
    _stopWakeWordDetection();
  }

  Future<void> _initializeAll() async {
    await _initializeTTS();
    await _initializeVoiceCommand();
    if (_isHomeScreenActive) {
      await _initializePorcupine();
    }
  }

  Future<void> _startWakeWordDetection() async {
    if (_porcupineManager != null && _isHomeScreenActive && mounted) {
      await _porcupineManager?.start();
      setState(() => _isWakeWordActive = true);
      debugPrint('Wake word detection started on HomeScreen');
    }
  }

  Future<void> _stopWakeWordDetection() async {
    if (_porcupineManager != null) {
      await _porcupineManager?.stop();
      if (mounted) {
        setState(() => _isWakeWordActive = false);
      }
      debugPrint('Wake word detection stopped');
    }
  }

  Future<void> _initializePorcupine() async {
    try {
      if (_porcupineManager != null) {
        await _porcupineManager?.delete();
        _porcupineManager = null;
      }

      debugPrint('Initializing Porcupine...');

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        'druzzovGz0p5SeQV+qggHOppXAMcWk7/a+PGnstLFIoYhOtyrEmf5Q==',
        ["assets/wakeup word for voice command/hey-beacon_en_android_v3_0_0.ppn"],
            (keywordIndex) {
          if (_isHomeScreenActive && mounted) { // Only process wake word if we're on home screen
            _handleWakeWordDetection();
          }
        },
        errorCallback: (error) {
          debugPrint('Porcupine error: ${error.message}');
        },
      );

      if (_isHomeScreenActive && mounted) {
        await _startWakeWordDetection();
      }
    } catch (e) {
      debugPrint('Porcupine initialization error: $e');
    }
  }

  Future<void> _initializeVoiceCommand() async {
    if (!_isVoiceInitialized) {
      final voiceCommandNotifier = ref.read(voiceCommandProvider.notifier);
      _isVoiceInitialized = await voiceCommandNotifier.initialize();
      debugPrint('Voice command initialization: ${_isVoiceInitialized ? 'success' : 'failed'}');
    }
  }

  void _handleWakeWordDetection() async {
    if (!_isHomeScreenActive) return; // Early return if not on home screen

    debugPrint('Wake word detected! Starting command detection...');
    await _stopWakeWordDetection();

    if (mounted && _isHomeScreenActive) {
      _speak('Yes, how can I help?');
      await Future.delayed(const Duration(milliseconds: 1000));
      _startVoiceCommandListening();
    }
  }

  void _startVoiceCommandListening() {
    if (!_isVoiceInitialized) {
      debugPrint('Voice commands not initialized');
      _resetWakeWordDetection();
      return;
    }

    final voiceCommandNotifier = ref.read(voiceCommandProvider.notifier);
    voiceCommandNotifier.startListening((command) {
      debugPrint('Command received: $command');
      _handleCommand(context, ref, command);
      _resetWakeWordDetection();
    });
  }

  Future<void> _resetWakeWordDetection() async {
    ref.read(voiceCommandProvider.notifier).stopListening();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && _isHomeScreenActive) {
      await _startWakeWordDetection();
      debugPrint('Wake word detection reactivated on HomeScreen');
    }
  }

  void _handleCommand(BuildContext context, WidgetRef ref, String command) {
    debugPrint('Processing command: $command');

    if (command.contains('navigate') || command.contains('go to') || command.contains('take me')) {
      _navigateToScreen(context, const LocationSearchScreen());
      _speak('Taking you to the navigation screen');
    }
    else if (command.contains('scan') || command.contains('camera') || command.contains('environment')) {
      _navigateToScreen(context, const ScanEnvironmentScreen());
      _speak('Taking you to the scanning screen');
    }
    else if (command.contains('emergency') || command.contains('help') || command.contains('sos')) {
      _navigateToScreen(context, const EmergencyScreen());
      _speak('Taking you to the Emergency screen');
    }
    else {
      debugPrint('Unrecognized command: $command');
      _speak('Sorry, I did not understand that command');
      _showSnackBar(context, "no such command");
    }
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en_US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _navigateToScreen(BuildContext context, Widget screen) async {
    await _stopWakeWordDetection(); // Stop detection before navigation
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceCommandProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "BEACON",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 25,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 20,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              voiceState.isListening ? Icons.mic : Icons.mic_none,
              color: voiceState.isListening ? Colors.blueAccent : null,
              size: voiceState.isListening ? 30 : 24,
            ),
            onPressed: () {
              if (_isWakeWordActive && _isHomeScreenActive) {
                _handleWakeWordDetection();
              }
            },
            tooltip: 'Start voice recognition',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider).signOutFromGoogle(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 70),
            _buildHeader(),
            if (voiceState.isListening) ...[
              const SizedBox(height: 20),
              const Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              _buildRecognitionStatus(voiceState.lastWords),
            ],
            const SizedBox(height: 80),
            _buildActionButtons(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "AR Navigation Assistant",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 40.0,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        Text(
          "Get voice-guided navigation and accessibility support",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecognitionStatus(String lastWords) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              'Recognized: $lastWords',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        CustomIconButton(
          label: "Start Navigation",
          icon: Icons.navigation_outlined,
          color: Colors.blue,
          onPressed: () => _navigateToScreen(context, const LocationSearchScreen()),
        ),
        const SizedBox(height: 25),
        CustomIconButton(
          label: "Scan Environment",
          icon: Icons.camera_alt_outlined,
          color: Colors.grey[700]!,
          onPressed: () => _navigateToScreen(context, const ScanEnvironmentScreen()),
        ),
        const SizedBox(height: 25),
        CustomIconButton(
          label: "Emergency",
          icon: Icons.emergency_outlined,
          color: Colors.red,
          onPressed: () => _navigateToScreen(context, const EmergencyScreen()),
        ),
      ],
    );
  }
}