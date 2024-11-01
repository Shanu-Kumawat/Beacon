import 'package:beacon/core/common/custom_icon_button.dart';
import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:beacon/features/environment/screens/scan_environment_screen.dart';
import 'package:beacon/features/navigation/screens/destination_search_screen.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _initDelay = Duration(seconds: 1);
  static const _listenDuration = Duration(seconds: 15);
  static const _cleanupDelay = Duration(milliseconds: 500);

  late final stt.SpeechToText _speech;
  String _lastWords = '';
  String _currentLocaleId = 'en_US';
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    Future.delayed(_initDelay, _initializeSpeech);
  }

  Future<bool> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: true,
      );

      if (available) {
        final systemLocale = await _speech.systemLocale();
        setState(() {
          _currentLocaleId = systemLocale?.localeId ?? 'en_US';
          _isInitialized = true;
        });
        debugPrint('Speech recognition initialized successfully');
        return true;
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }

    setState(() => _isInitialized = false);
    return false;
  }

  void _handleStatus(String status) {
    final isListening = status == 'listening';
    if (mounted && _isListening != isListening) {
      setState(() => _isListening = isListening);
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('''
      DETAILED ERROR INFO:
      Error type: ${error.errorMsg}
      Permanent: ${error.permanent}
    ''');

    if (error.errorMsg != 'error_busy') {
      _showSnackBar(
        'Speech error: ${error.errorMsg}',
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isListening = false);

    if (error.errorMsg == 'error_busy') {
      Future.delayed(_cleanupDelay, _startListening);
    }
  }

  void _showSnackBar(
      String message, {
        Duration duration = const Duration(seconds: 3),
        Color? backgroundColor,
      }) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    try {
      await _speech.stop();
      await Future.delayed(_cleanupDelay);

      setState(() {
        _lastWords = '';
        _isListening = true;
      });

      await _speech.listen(
        onResult: _handleSpeechResult,
        listenFor: _listenDuration,
        localeId: _currentLocaleId,
        listenOptions:  stt.SpeechListenOptions(
          partialResults: true,
          onDevice: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    setState(() => _lastWords = result.recognizedWords);

    if (result.finalResult) {
      final command = _lastWords.toLowerCase();
      if (command.contains('navigate')) {
        _navigateToScreen( LocationSearchScreen());
      } else if (command.contains('scan')) {
        _navigateToScreen(const ScanEnvironmentScreen());
      } else {
        debugPrint('Command not recognized: $command');
      }
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _handleEmergency() {
    _showSnackBar(
      'Emergency feature coming soon',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 70),
            _buildHeader(),
            if (_isListening || _lastWords.isNotEmpty)
              _buildRecognitionStatus(),
            const SizedBox(height: 80),
            _buildActionButtons(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          color: _isListening ? Colors.blue : null,
          onPressed: _startListening,
          tooltip: 'Start voice recognition',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authControllerProvider).signOutFromGoogle(),
          tooltip: 'Logout',
        ),
      ],
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

  Widget _buildRecognitionStatus() {
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
            if (_isListening)
              const Text(
                'Listening...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            Text(
              'Recognized: $_lastWords',
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.blue : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomIconButton(
          label: "Start Navigation",
          icon: Icons.navigation_outlined,
          color: Colors.blue,
          onPressed: () => _navigateToScreen( LocationSearchScreen()),
        ),
        const SizedBox(height: 25),
        CustomIconButton(
          label: "Scan Environment",
          icon: Icons.camera_alt_outlined,
          color: Colors.grey[700]!,
          onPressed: () => _navigateToScreen(const ScanEnvironmentScreen()),
        ),
        const SizedBox(height: 25),
        CustomIconButton(
          label: "Emergency",
          icon: Icons.emergency_outlined,
          color: Colors.red,
          onPressed: _handleEmergency,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}