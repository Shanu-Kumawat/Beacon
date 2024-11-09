// lib/features/scan_environment/utils/text_to_speech_manager.dart
import 'dart:collection';

import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechManager {
  final FlutterTts _flutterTts;
  bool _isSpeaking = false;
  final Queue<String> _speechQueue = Queue();

  TextToSpeechManager() : _flutterTts = FlutterTts() {
    _initialize();
  }

  void dispose() {
    _flutterTts.stop();
  }

  Future<void> speak(String text, {bool interrupt = false}) async {
    if (interrupt && _isSpeaking) {
      await _flutterTts.stop();
      _speechQueue.clear();
    }

    _speechQueue.add(text);
    if (!_isSpeaking) {
      await _processQueue();
    }
  }

  Future<void> stop() async {
    _speechQueue.clear();
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> _initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  Future<void> _processQueue() async {
    if (_speechQueue.isEmpty) return;

    _isSpeaking = true;
    final textToSpeak = _speechQueue.removeFirst();
    await _flutterTts.speak(textToSpeak);
  }
}
