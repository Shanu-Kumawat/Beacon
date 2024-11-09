// emergency_screen.dart
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:audioplayers/audioplayers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../voiceCommands.dart';
import 'emergency_contacts.dart';
import 'emergency_services.dart';
import 'location_share.dart';
import 'medical_info.dart';

// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };
}

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool isEmergencyActive = false;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isSirenPlaying = false;
  bool isProcessingCommand = false;
  audio.Source? sirenSource;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeAudio();
    _checkPermissions();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.notification,
    ].request();

    if (statuses[Permission.location]!.isDenied) {
      _showPermissionDialog('Location');
    }
    if (statuses[Permission.microphone]!.isDenied) {
      _showPermissionDialog('Microphone');
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text('Please grant $permissionName permission for emergency features to work properly.'),
        actions: [
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializeAudio() async {
    try {
      // Initialize the audio source
      sirenSource = audio.AssetSource('Audios/siren.mp3');
      // Pre-load the audio
      await audioPlayer.setSource(sirenSource!);
      // Set up audio player settings
      await audioPlayer.setReleaseMode(audio.ReleaseMode.loop);
      await audioPlayer.setVolume(1.0);

      // Listen for player state changes
      audioPlayer.onPlayerStateChanged.listen((audio.PlayerState state) {
        setState(() {
          isSirenPlaying = state == audio.PlayerState.playing;
        });
      });

      // Listen for player completion
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          isSirenPlaying = false;
        });
      });
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  void _toggleSiren(bool play) async {
    try {
      if (play && !isSirenPlaying) {
        if (sirenSource == null) {
          await _initializeAudio();
        }
        await audioPlayer.setSource(sirenSource!);
        await audioPlayer.resume();
        setState(() {
          isSirenPlaying = true;
        });
      } else if (!play && isSirenPlaying) {
        await audioPlayer.stop();
        setState(() {
          isSirenPlaying = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling siren: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing siren: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<LocationData?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address using reverse geocoding (you might want to use a geocoding package)
      String address = "Current Location"; // Placeholder

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  void _startVoiceCommand(BuildContext context, WidgetRef ref) {
    if (isProcessingCommand) return;

    setState(() {
      isProcessingCommand = true;
    });

    ref.read(voiceCommandProvider.notifier).startListening(
          (command) => _handleCommand(context, ref, command.toLowerCase()),
    );
    _speak("Speak Now.");
  }

  Future<void> _handleCommand(BuildContext context, WidgetRef ref, String command) async {
    try {
      if (command.contains('sos') || command.contains('help') || command.contains('emergency')) {
        await _activateEmergencyMode();
      }

      else if (command.contains('ambulance') || command.contains('hospital')) {
        _speak("Contacting emergency medical services");
        await _contactEmergencyServices('hospital');
      }

      else if (command.contains('police')) {
        _speak("Contacting police services");
        await _contactEmergencyServices('police');
      }

      else if (command.contains('fire')) {
        _speak("Contacting fire department");
        await _contactEmergencyServices('fire');
      }

      else if (command.contains('call emergency') || command.contains('call someone')) {
        _speak("Calling emergency contact");
        await _makeEmergencyCall(context);
      }

      else if (command.contains('stop siren') || command.contains('stop alarm')) {
        _toggleSiren(false);
      }

      else if (command.contains('share location')) {
        await _shareLocation();
      }
    } finally {
      setState(() {
        isProcessingCommand = false;
      });
    }
  }

  Future<void> _activateEmergencyMode() async {
    setState(() {
      isEmergencyActive = true;
    });
    await _speak('Emergency mode active');
    _toggleSiren(true);
    await _contactEmergencyServices('all');
    await _shareLocation();
  }

  Future<void> _contactEmergencyServices(String serviceType) async {
    try {
      final locationData = await _getCurrentLocation();
      if (locationData == null) {
        _speak("Unable to get your location");
        return;
      }

      String phoneNumber;
      String message;

      // Set appropriate phone number based on service type
      switch (serviceType) {
        case 'hospital':
          phoneNumber = '7001026887'; // Ambulance number
          message = 'Medical emergency at:\n';
          break;
        case 'police':
          phoneNumber = '7001026887'; // Police number
          message = 'Police emergency at:\n';
          break;
        case 'fire':
          phoneNumber = '7001026887'; // Fire department
          message = 'Fire emergency at:\n';
          break;
        default:
          phoneNumber = '7001026887'; // General emergency
          message = 'Emergency situation at:\n';
      }

      // Add location details to message
      message += 'Location: ${locationData.address}\n'
          'Coordinates: ${locationData.latitude}, ${locationData.longitude}\n'
          'Maps Link: https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}';

      // Launch SMS
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        _speak("Emergency message sent to $serviceType services");
      } else {
        throw 'Could not send emergency message';
      }

    } catch (e) {
      debugPrint('Error contacting emergency services: $e');
      _speak("Failed to contact emergency services");
    }
  }

  Future<void> _shareLocation() async {
    try {
      final locationData = await _getCurrentLocation();
      if (locationData == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'lastKnownLocation': locationData.toJson(),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      _speak("Location shared with emergency contacts");
    } catch (e) {
      debugPrint('Error sharing location: $e');
    }
  }

  Future<void> _makeEmergencyCall(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final medicalDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medical_data')
          .doc('current')
          .get();

      if (!medicalDataDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No emergency contact found')),
          );
        }
        return;
      }

      final emergencyContact = medicalDataDoc.data()?['emergencyContact'] as String?;
      if (emergencyContact == null || emergencyContact.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No emergency contact number available')),
          );
        }
        return;
      }

      final Uri launchUri = Uri(
        scheme: 'tel',
        path: emergencyContact,
      );

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making emergency call: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
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
              onLongPress: _activateEmergencyMode,
              onLongPressEnd: (_) {
                if (!isEmergencyActive) {
                  _toggleSiren(false);
                }
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
            if (isSirenPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _toggleSiren(false),
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Stop Siren"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                _buildquickActionButton(
                    "Call Emergency Contact",
                    Icons.phone,
                    Colors.blue,
                    context,
                ),
                _buildQuickActionButton(
                  "Share Location",
                  Icons.location_on,
                  Colors.green,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationShareScreen()),
                    );
                  },
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
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                        );
                      },
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

  Widget _buildquickActionButton(
      String label,
      IconData icon,
      Color color,
      BuildContext context,
      ) {
    return InkWell(
      onTap: () => _makeEmergencyCall(context),
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

