import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/widgets/analytics/analytics_helpers.dart';

void main() {
  group('analyticsTrendSentiment', () {
    test('treats latency improvements as positive', () {
      expect(
        analyticsTrendSentiment(
          'detection_latency',
          'Down 31% vs manual patrol',
        ),
        AnalyticsTrendSentiment.positive,
      );
    });

    test('treats false positive reductions as positive', () {
      expect(
        analyticsTrendSentiment('false_positive_rate', 'Down 1.8 pts'),
        AnalyticsTrendSentiment.positive,
      );
    });

    test('treats stable safe return as neutral', () {
      expect(
        analyticsTrendSentiment('safe_return', 'Stable over 14 days'),
        AnalyticsTrendSentiment.neutral,
      );
    });

    test('treats command gate backlog as warning', () {
      expect(
        analyticsTrendSentiment('command_gate', 'Awaiting backend enable'),
        AnalyticsTrendSentiment.warning,
      );
    });
  });

  group('formatAnalyticsTimestamp', () {
    test('formats ISO timestamps for display', () {
      expect(
        formatAnalyticsTimestamp('2026-06-10T09:42:00-07:00'),
        contains('Jun 10, 2026'),
      );
    });
  });

  group('chartMaxY', () {
    test('returns padded minimum when all values are zero', () {
      expect(chartMaxY(const [0, 0]), 3);
    });
  });

  group('abbreviateScenarioLabel', () {
    test('keeps short labels intact', () {
      expect(abbreviateScenarioLabel('Canyon Ridge'), 'Canyon Ridge');
    });

    test('abbreviates long multi-word labels', () {
      expect(
        abbreviateScenarioLabel('San Bernardino Mountain Ridge'),
        'San',
      );
    });
  });
}
