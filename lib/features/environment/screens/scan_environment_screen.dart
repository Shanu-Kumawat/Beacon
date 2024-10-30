// scan_environment_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ScanEnvironmentScreen extends StatefulWidget {
  const ScanEnvironmentScreen({super.key});

  @override
  State<ScanEnvironmentScreen> createState() => _ScanEnvironmentScreenState();
}

class _ScanEnvironmentScreenState extends State<ScanEnvironmentScreen> {
  late CameraController _controller;
  Future<void>?
      _initializeControllerFuture; // Changed to nullable to avoid the late initialization error.
  final FlutterTts flutterTts = FlutterTts();
  bool isScanning = false;
  bool isMuted = false;
  List<Detection> recentDetections = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      setState(() {
        _initializeControllerFuture = _controller.initialize();
      });
    } catch (e) {
      // Handle the error, e.g., show a message to the user
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  void _speak(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
    });
    _speak(isScanning ? "Scanning started" : "Scanning paused");
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera Preview
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: CameraPreview(_controller),
                ),

                // Scanning Overlay
                SafeArea(
                  child: Column(
                    children: [
                      // Status Bar
                      Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isScanning
                                  ? 'Actively Scanning'
                                  : 'Scanning Paused',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  isMuted = !isMuted;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Detection List
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recent Detections:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    DetectionListWidget(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scan Button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _toggleScanning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isScanning ? Colors.red : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isScanning ? Icons.stop : Icons.play_arrow),
                            const SizedBox(width: 8),
                            Text(
                              isScanning ? 'Stop Scanning' : 'Start Scanning',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _speak("Reading all recent detections");
                          // Implement reading all detections
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up),
                            SizedBox(width: 8),
                            Text('Read All Detections',
                                style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// Detection model
class Detection {
  final String content;
  final String distance;
  final DetectionType type;
  final DateTime timestamp;
  final bool isHighPriority;

  Detection({
    required this.content,
    required this.distance,
    required this.type,
    required this.timestamp,
    this.isHighPriority = false,
  });
}

enum DetectionType {
  object,
  text,
  hazard,
}

// Detection list widget
class DetectionListWidget extends StatelessWidget {
  const DetectionListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: 5, // Replace with actual detections list length
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection item', // Replace with actual detection
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '2 meters away', // Replace with actual distance
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
