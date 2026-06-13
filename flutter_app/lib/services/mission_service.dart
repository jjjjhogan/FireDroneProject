import '../mock/simulation_fixtures.dart';
import '../models/mission.dart';

abstract class MissionService {
  Future<Mission> fetchActiveMission();
}

class MockMissionService implements MissionService {
  const MockMissionService();

  @override
  Future<Mission> fetchActiveMission() async {
    return mockMission;
  }
}
