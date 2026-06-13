import '../mock/simulation_fixtures.dart';
import '../models/fire_detection_event.dart';
import '../models/operations_enums.dart';

abstract class FireDetectionService {
  Future<List<FireDetectionEvent>> fetchDetections();

  Future<FireDetectionEvent> updateStatus({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String reviewer,
    required String notes,
  });
}

class MockFireDetectionService implements FireDetectionService {
  const MockFireDetectionService();

  @override
  Future<List<FireDetectionEvent>> fetchDetections() async {
    return List.unmodifiable(mockFireDetectionEvents);
  }

  @override
  Future<FireDetectionEvent> updateStatus({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String reviewer,
    required String notes,
  }) async {
    return event.copyWith(
      status: status,
      reviewer: reviewer,
      reviewTimestamp: simulationBaseTime.add(const Duration(minutes: 1)),
      notes: notes.isEmpty ? event.notes : notes,
    );
  }
}
