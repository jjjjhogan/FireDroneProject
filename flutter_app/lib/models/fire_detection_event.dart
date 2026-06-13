import 'operations_enums.dart';

class FireDetectionEvent {
  const FireDetectionEvent({
    required this.eventId,
    required this.detectionType,
    required this.confidence,
    required this.severity,
    required this.lat,
    required this.lon,
    required this.sourceDroneId,
    required this.imagePlaceholder,
    required this.timestamp,
    required this.status,
    required this.reviewer,
    required this.reviewTimestamp,
    required this.notes,
  });

  final String eventId;
  final DetectionType detectionType;
  final double confidence;
  final AlertSeverity severity;
  final double lat;
  final double lon;
  final String sourceDroneId;
  final String imagePlaceholder;
  final DateTime timestamp;
  final AlertStatus status;
  final String? reviewer;
  final DateTime? reviewTimestamp;
  final String notes;

  bool get isOpen {
    return status == AlertStatus.unconfirmed || status == AlertStatus.confirmed;
  }

  FireDetectionEvent copyWith({
    DetectionType? detectionType,
    double? confidence,
    AlertSeverity? severity,
    double? lat,
    double? lon,
    String? sourceDroneId,
    String? imagePlaceholder,
    DateTime? timestamp,
    AlertStatus? status,
    String? reviewer,
    DateTime? reviewTimestamp,
    String? notes,
  }) {
    return FireDetectionEvent(
      eventId: eventId,
      detectionType: detectionType ?? this.detectionType,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      sourceDroneId: sourceDroneId ?? this.sourceDroneId,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reviewer: reviewer ?? this.reviewer,
      reviewTimestamp: reviewTimestamp ?? this.reviewTimestamp,
      notes: notes ?? this.notes,
    );
  }
}
