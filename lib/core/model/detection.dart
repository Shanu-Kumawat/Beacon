// lib/features/scan_environment/models/detection.dart
import 'package:flutter/foundation.dart';

enum DetectionType {
  object,
  text,
  hazard,
}

@immutable
class Detection {
  final String content;
  final DetectionType type;
  final DateTime timestamp;
  final bool isHighPriority;
  final double confidence;

  Detection({
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isHighPriority,
    this.confidence = 0.0,
  });

  Detection copyWith({
    String? content,
    String? distance,
    DetectionType? type,
    DateTime? timestamp,
    bool? isHighPriority,
  }) {
    return Detection(
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isHighPriority: isHighPriority ?? this.isHighPriority,
    );
  }
}
