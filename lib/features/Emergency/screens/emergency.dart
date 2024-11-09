import 'package:flutter/material.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../voiceCommands.dart';
import 'medical_info.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool isEmergencyActive = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }
  void _startVoiceCommand(BuildContext context, WidgetRef ref) {
    ref.read(voiceCommandProvider.notifier).startListening(
          (command) => _handleCommand(context, ref, command),
    );
    _speak("Speak Now.");
  }

  void _handleCommand(BuildContext context, WidgetRef ref, String command) {
    if(command.contains('sos') || command.contains('help') || command.contains('emergency')){
      _speak('Emergency mode active');
      setState(() {
        isEmergencyActive = !isEmergencyActive;
      });
    }
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en_US");
    await flutterTts.setSpeechRate(0.5);
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final voiceState = ref.watch(voiceCommandProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Emergency",
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEmergencyActive ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEmergencyActive ? Icons.warning : Icons.check_circle,
                    color: isEmergencyActive ? Colors.red : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEmergencyActive ? "Emergency Mode Active" : "Status: Safe",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isEmergencyActive ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onLongPress: () {
                setState(() {
                  isEmergencyActive = !isEmergencyActive;
                });
                if (isEmergencyActive) {
                  _speak("Emergency Mode Active");
                } else {
                  _speak("Status Safe");
                }
                // Add emergency logic here
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      spreadRadius: isEmergencyActive ? 15 : 5,
                      blurRadius: 20,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 60,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Long press for help",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                _buildQuickActionButton(
                  "Call Emergency Contact",
                  Icons.phone,
                  Colors.blue,
                      () {},
                ),
                _buildQuickActionButton(
                  "Share Location",
                  Icons.location_on,
                  Colors.green,
                      () {},
                ),
                _buildQuickActionButton(
                  "Medical Info",
                  Icons.medical_information,
                  Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MedicalInfoPage()),
                    );
                  },
                ),
                _buildQuickActionButton(
                  "Emergency Services",
                  Icons.local_hospital,
                  Colors.orange,
                      () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Emergency Contacts Section
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}