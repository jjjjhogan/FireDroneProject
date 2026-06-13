import '../mock/simulation_fixtures.dart';
import '../models/operations_enums.dart';
import '../models/scenario.dart';

abstract class ScenarioLibraryService {
  Future<List<Scenario>> listScenarios();

  Future<List<Scenario>> searchScenarios({
    String query = '',
    String region = 'All',
  });
}

class MockScenarioLibraryService implements ScenarioLibraryService {
  const MockScenarioLibraryService();

  @override
  Future<List<Scenario>> listScenarios() async {
    return List.unmodifiable(mockScenarios);
  }

  @override
  Future<List<Scenario>> searchScenarios({
    String query = '',
    String region = 'All',
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final all = await listScenarios();
    return all
        .where((scenario) {
          final matchesRegion = region == 'All' || scenario.region == region;
          final searchable = [
            scenario.scenarioId,
            scenario.title,
            scenario.description,
            scenario.region,
            scenario.difficulty.label,
            ...scenario.tags,
          ].join(' ').toLowerCase();
          final matchesQuery =
              normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
          return matchesRegion && matchesQuery;
        })
        .toList(growable: false);
  }
}
