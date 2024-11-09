// lib/features/scan_environment/models/scan_settings.dart
class ScanSettings {
  final bool announceDistance;
  final bool announceDirection;
  final double minimumConfidence;
  final Set<String> priorityObjects;
  final int maxDetectionsPerFrame;
  final Duration announcementCooldown;

  const ScanSettings({
    this.announceDistance = true,
    this.announceDirection = true,
    this.minimumConfidence = 0.7,
    this.priorityObjects = const {
      'person',
      'car',
      'truck',
      'stairs',
      'door',
      'obstacle',
    },
    this.maxDetectionsPerFrame = 3,
    this.announcementCooldown = const Duration(seconds: 2),
  });

  ScanSettings copyWith({
    bool? announceDistance,
    bool? announceDirection,
    double? minimumConfidence,
    Set<String>? priorityObjects,
    int? maxDetectionsPerFrame,
    Duration? announcementCooldown,
  }) {
    return ScanSettings(
      announceDistance: announceDistance ?? this.announceDistance,
      announceDirection: announceDirection ?? this.announceDirection,
      minimumConfidence: minimumConfidence ?? this.minimumConfidence,
      priorityObjects: priorityObjects ?? this.priorityObjects,
      maxDetectionsPerFrame:
          maxDetectionsPerFrame ?? this.maxDetectionsPerFrame,
      announcementCooldown: announcementCooldown ?? this.announcementCooldown,
    );
  }
}
