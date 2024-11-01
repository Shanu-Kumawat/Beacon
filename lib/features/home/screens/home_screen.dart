import 'package:beacon/core/common/custom_icon_button.dart';
import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:beacon/features/environment/screens/scan_environment_screen.dart';
import 'package:beacon/features/navigation/screens/destination_search_screen.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../voiceCommands.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _handleCommand(BuildContext context, WidgetRef ref, String command) {
    if (command.contains('navigate')) {
      _navigateToScreen(context, LocationSearchScreen());
    } else if (command.contains('scan')) {
      _navigateToScreen(context, const ScanEnvironmentScreen());
    } else {
      _showSnackBar(context, 'No such commands');
    }
  }

  void _startVoiceCommand(BuildContext context, WidgetRef ref) {
    ref.read(voiceCommandProvider.notifier).startListening(
          (command) => _handleCommand(context, ref, command),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => _startVoiceCommand(context, ref),
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
            ],
            if (voiceState.isListening || voiceState.lastWords.isNotEmpty)
              _buildRecognitionStatus(voiceState.lastWords),
            const SizedBox(height: 80),
            _buildActionButtons(context, ref),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CustomIconButton(
          label: "Start Navigation",
          icon: Icons.navigation_outlined,
          color: Colors.blue,
          onPressed: () => _navigateToScreen(context, LocationSearchScreen()),
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
          onPressed: () => _showSnackBar(context, 'Emergency feature coming soon'),
        ),
      ],
    );
  }
}