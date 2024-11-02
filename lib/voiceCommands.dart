import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceCommandState {
  final bool isListening;
  final String lastWords;
  final bool isInitialized;

  VoiceCommandState({
    this.isListening = false,
    this.lastWords = '',
    this.isInitialized = false,
  });

  VoiceCommandState copyWith({
    bool? isListening,
    String? lastWords,
    bool? isInitialized,
  }) {
    return VoiceCommandState(
      isListening: isListening ?? this.isListening,
      lastWords: lastWords ?? this.lastWords,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class VoiceCommandNotifier extends StateNotifier<VoiceCommandState> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  static const _listenDuration = Duration(seconds: 15);
  static const _cleanupDelay = Duration(milliseconds: 1000
  );
  String _currentLocaleId = 'en_US';

  VoiceCommandNotifier() : super(VoiceCommandState());

  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: true,
      );
      if (available) {
        final systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? 'en_US';
        state = state.copyWith(isInitialized: true);
        debugPrint('Speech recognition initialized successfully');
        return true;
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
    state = state.copyWith(isInitialized: false);
    return false;
  }

  Future<void> startListening(void Function(String command) onCommandDetected) async {
    if (!state.isInitialized) await initialize();

    try {
      await _speech.stop();
      await Future.delayed(_cleanupDelay);

      state = state.copyWith(
        isListening: true,
        lastWords: '',
      );

      await _speech.listen(
        onResult: (result) => _handleSpeechResult(result, onCommandDetected),
        listenFor: _listenDuration,
        localeId: _currentLocaleId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          onDevice: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      state = state.copyWith(isListening: false);
    }
  }

  void stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void _handleStatus(String status) {
    state = state.copyWith(isListening: status == 'listening');
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    state = state.copyWith(isListening: false);
  }

  void _handleSpeechResult(SpeechRecognitionResult result, void Function(String command) onCommandDetected) {
    state = state.copyWith(lastWords: result.recognizedWords);

    if (result.finalResult) {
      final command = result.recognizedWords.toLowerCase();
      onCommandDetected(command);
    }
  }
}

final voiceCommandProvider = StateNotifierProvider<VoiceCommandNotifier, VoiceCommandState>((ref) {
  return VoiceCommandNotifier();
});