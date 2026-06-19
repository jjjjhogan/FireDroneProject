import 'package:flutter/material.dart';

enum AnalyticsTrendSentiment { positive, negative, neutral, warning }

AnalyticsTrendSentiment analyticsTrendSentiment(String kpiId, String? trend) {
  if (trend == null || trend.trim().isEmpty) {
    return AnalyticsTrendSentiment.neutral;
  }

  final normalized = trend.trim().toLowerCase();

  if (normalized.contains('awaiting') ||
      normalized.contains('pending') ||
      normalized.contains('locked')) {
    return AnalyticsTrendSentiment.warning;
  }

  if (normalized.contains('stable')) {
    return AnalyticsTrendSentiment.neutral;
  }

  final isUp =
      normalized.startsWith('+') ||
      normalized.startsWith('up ') ||
      normalized.contains(' up ');
  final isDown =
      normalized.startsWith('down') || normalized.contains(' down ');

  switch (kpiId) {
    case 'detection_latency':
    case 'false_positive_rate':
      if (isDown) return AnalyticsTrendSentiment.positive;
      if (isUp) return AnalyticsTrendSentiment.negative;
      return AnalyticsTrendSentiment.neutral;
    case 'thermal_confidence':
    case 'coverage_efficiency':
    case 'safe_return':
      if (isUp || normalized.startsWith('+')) {
        return AnalyticsTrendSentiment.positive;
      }
      if (isDown) return AnalyticsTrendSentiment.negative;
      return AnalyticsTrendSentiment.neutral;
    case 'command_gate':
      return AnalyticsTrendSentiment.warning;
    default:
      if (isUp || normalized.startsWith('+')) {
        return AnalyticsTrendSentiment.positive;
      }
      if (isDown) return AnalyticsTrendSentiment.negative;
      return AnalyticsTrendSentiment.neutral;
  }
}

({Color background, Color border, Color text}) trendSentimentColors(
  AnalyticsTrendSentiment sentiment,
) {
  return switch (sentiment) {
    AnalyticsTrendSentiment.positive => (
      background: const Color(0xffeef8f2),
      border: const Color(0xffb7f1d8),
      text: const Color(0xff0e7656),
    ),
    AnalyticsTrendSentiment.negative => (
      background: const Color(0xfffff4ef),
      border: const Color(0xffffd9a8),
      text: const Color(0xff9a3412),
    ),
    AnalyticsTrendSentiment.warning => (
      background: const Color(0xfffff8eb),
      border: const Color(0xfffcd34d),
      text: const Color(0xff92400e),
    ),
    AnalyticsTrendSentiment.neutral => (
      background: const Color(0xfff1f5f4),
      border: const Color(0xffd8e3df),
      text: const Color(0xff475569),
    ),
  };
}

String formatAnalyticsTimestamp(String raw) {
  if (raw == 'unknown' || raw.trim().isEmpty) {
    return 'Unknown';
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = parsed.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} ${local.day}, ${local.year} · '
      '$hour:$minute $meridiem';
}

double chartMaxY(
  Iterable<double> values, {
  double padding = 2,
  double minimum = 1,
}) {
  if (values.isEmpty) {
    return minimum + padding;
  }

  final maxValue = values.reduce((a, b) => a > b ? a : b);
  if (maxValue <= 0) {
    return minimum + padding;
  }

  return maxValue + padding;
}

String abbreviateScenarioLabel(String scenarioName, {int maxLength = 12}) {
  if (scenarioName.length <= maxLength) {
    return scenarioName;
  }

  final words = scenarioName.split(' ');
  if (words.length > 1 && words.first.length <= maxLength) {
    return words.first;
  }

  return '${scenarioName.substring(0, maxLength - 1)}…';
}
