import '../mock/simulation_fixtures.dart';
import '../models/drone_telemetry.dart';

abstract class DroneTelemetryService {
  Future<List<DroneTelemetry>> fetchTelemetry();
}

class MockDroneTelemetryService implements DroneTelemetryService {
  const MockDroneTelemetryService();

  @override
  Future<List<DroneTelemetry>> fetchTelemetry() async {
    return List.unmodifiable(mockDroneTelemetry);
  }
}
