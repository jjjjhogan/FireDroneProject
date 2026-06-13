import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/audit_log_entry.dart';
import '../models/command.dart';
import '../models/fire_detection_event.dart';
import '../models/operations_enums.dart';

abstract class OperationsApiClient {
  Future<BackendIntegrationStatus> fetchIntegrationStatus();
  Future<SafetyChecklist> fetchSafetyChecklist();
  Future<List<FireDetectionEvent>> fetchAlerts();
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  });
  Future<List<AuditLogEntry>> fetchAuditEntries();
  Future<CommandResult> simulateCommand(CommandRequest request);
}

class BackendIntegrationStatus {
  const BackendIntegrationStatus({
    required this.available,
    required this.rbacEnabled,
    required this.persistenceEngine,
    required this.auditPersistence,
    required this.alertPersistence,
    required this.mapProvider,
    required this.mapConfigured,
    required this.px4Sitl,
    required this.mavlink,
    required this.ardupilot,
    required this.yoloThermal,
    required this.hardwareCommandsEnabled,
  });

  factory BackendIntegrationStatus.fromJson(Map<String, dynamic> json) {
    final auth = json['auth'] as Map<String, dynamic>? ?? const {};
    final persistence =
        json['persistence'] as Map<String, dynamic>? ?? const {};
    final map = json['map'] as Map<String, dynamic>? ?? const {};
    final adapters = json['adapters'] as Map<String, dynamic>? ?? const {};
    final safety = json['safety'] as Map<String, dynamic>? ?? const {};
    return BackendIntegrationStatus(
      available: true,
      rbacEnabled: auth['rbacEnabled'] as bool? ?? false,
      persistenceEngine: persistence['engine'] as String? ?? 'unknown',
      auditPersistence: persistence['audit'] as String? ?? 'unknown',
      alertPersistence: persistence['alerts'] as String? ?? 'unknown',
      mapProvider: map['provider'] as String? ?? 'unknown',
      mapConfigured: map['configured'] as bool? ?? false,
      px4Sitl: adapters['px4Sitl'] as String? ?? 'not configured',
      mavlink: adapters['mavlink'] as String? ?? 'not configured',
      ardupilot: adapters['arduPilot'] as String? ?? 'not configured',
      yoloThermal: adapters['yoloThermal'] as String? ?? 'not configured',
      hardwareCommandsEnabled:
          safety['hardwareCommandsEnabled'] as bool? ?? false,
    );
  }

  factory BackendIntegrationStatus.unavailable() {
    return const BackendIntegrationStatus(
      available: false,
      rbacEnabled: false,
      persistenceEngine: 'offline',
      auditPersistence: 'local fallback',
      alertPersistence: 'local fallback',
      mapProvider: 'local placeholder',
      mapConfigured: false,
      px4Sitl: 'backend offline',
      mavlink: 'backend offline',
      ardupilot: 'backend offline',
      yoloThermal: 'backend offline',
      hardwareCommandsEnabled: false,
    );
  }

  final bool available;
  final bool rbacEnabled;
  final String persistenceEngine;
  final String auditPersistence;
  final String alertPersistence;
  final String mapProvider;
  final bool mapConfigured;
  final String px4Sitl;
  final String mavlink;
  final String ardupilot;
  final String yoloThermal;
  final bool hardwareCommandsEnabled;
}

class SafetyChecklist {
  const SafetyChecklist({
    required this.geofence,
    required this.remoteId,
    required this.airspaceApproval,
    required this.emergencyStop,
  });

  factory SafetyChecklist.fromJson(Map<String, dynamic> json) {
    return SafetyChecklist(
      geofence: SafetyChecklistItem.fromJson(json['geofence']),
      remoteId: SafetyChecklistItem.fromJson(json['remoteId']),
      airspaceApproval: SafetyChecklistItem.fromJson(json['airspaceApproval']),
      emergencyStop: SafetyChecklistItem.fromJson(json['emergencyStop']),
    );
  }

  factory SafetyChecklist.unavailable() {
    const unavailable = SafetyChecklistItem(
      status: 'backend_offline',
      notes: 'Backend safety checklist unavailable.',
      engaged: false,
    );
    return const SafetyChecklist(
      geofence: unavailable,
      remoteId: unavailable,
      airspaceApproval: unavailable,
      emergencyStop: unavailable,
    );
  }

  final SafetyChecklistItem geofence;
  final SafetyChecklistItem remoteId;
  final SafetyChecklistItem airspaceApproval;
  final SafetyChecklistItem emergencyStop;
}

class SafetyChecklistItem {
  const SafetyChecklistItem({
    required this.status,
    required this.notes,
    required this.engaged,
    this.updatedAt,
    this.updatedBy,
  });

  factory SafetyChecklistItem.fromJson(Object? json) {
    final data = json is Map<String, dynamic> ? json : const {};
    return SafetyChecklistItem(
      status: data['status'] as String? ?? 'not_verified',
      notes: data['notes'] as String? ?? '',
      engaged: data['engaged'] as bool? ?? false,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  final String status;
  final String notes;
  final bool engaged;
  final DateTime? updatedAt;
  final String? updatedBy;

  String get label {
    return switch (status) {
      'not_verified' => 'Not verified',
      'pending' => 'Pending review',
      'verified' => 'Verified',
      'blocked' => 'Blocked',
      'ready' => 'Ready',
      'engaged' => 'Engaged',
      'backend_offline' => 'Backend offline',
      _ =>
        status
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }

  String get commandPanelValue {
    if (engaged) return '$label active';
    return label;
  }
}

class HttpOperationsApiClient implements OperationsApiClient {
  HttpOperationsApiClient({
    Uri? baseUri,
    http.Client? client,
    String? authToken,
  }) : baseUri = baseUri ?? Uri.parse('http://127.0.0.1:5000/api'),
       _client = client ?? http.Client(),
       authToken =
           authToken ??
           const String.fromEnvironment(
             'PUBLIC_SAFETY_TOKEN',
             defaultValue: '',
           );

  final Uri baseUri;
  final http.Client _client;
  final String authToken;

  Uri _uri(String path) => baseUri.replace(path: '${baseUri.path}$path');

  Map<String, String> get _headers {
    final headers = {'content-type': 'application/json'};
    if (authToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${authToken.trim()}';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    if (response.statusCode >= 400) {
      throw StateError('Operations API request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 500) {
      throw StateError('Operations API request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() async {
    return BackendIntegrationStatus.fromJson(
      await _getJson('/integrations/status'),
    );
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() async {
    return SafetyChecklist.fromJson(await _getJson('/safety/checklist'));
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() async {
    final json = await _getJson('/alerts');
    return (json['alerts'] as List<dynamic>? ?? const [])
        .map((item) => _alertFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) async {
    final json = await _postJson('/alerts/${event.eventId}/review', {
      'status': _alertStatusLabel(status),
      'notes': notes,
    });
    if (json['accepted'] != true) {
      throw StateError(json['error'] as String? ?? 'Alert review rejected');
    }
    return _alertFromJson(json['alert'] as Map<String, dynamic>);
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() async {
    final json = await _getJson('/audit');
    return (json['entries'] as List<dynamic>? ?? const [])
        .map((item) => _auditFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) async {
    final json = await _postJson('/commands/simulate', {
      'commandType': request.commandType.label,
      'targetDroneId': request.targetDroneId,
      'confirmationProvided': request.confirmationProvided,
      'notes': request.notes,
    });
    return CommandResult(
      accepted: json['accepted'] as bool? ?? false,
      commandType: request.commandType,
      targetDroneId: json['targetDroneId'] as String? ?? request.targetDroneId,
      message: json['message'] as String? ?? '',
      blockedReason: json['blockedReason'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class ResilientOperationsApiClient implements OperationsApiClient {
  ResilientOperationsApiClient({
    OperationsApiClient? primary,
    OperationsApiClient? fallback,
  }) : _primary = primary ?? HttpOperationsApiClient(),
       _fallback = fallback ?? const UnavailableOperationsApiClient();

  final OperationsApiClient _primary;
  final OperationsApiClient _fallback;

  Future<T> _fromPrimary<T>(
    Future<T> Function(OperationsApiClient client) request,
  ) async {
    try {
      return await request(_primary);
    } catch (_) {
      return request(_fallback);
    }
  }

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() {
    return _fromPrimary((client) => client.fetchIntegrationStatus());
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() {
    return _fromPrimary((client) => client.fetchSafetyChecklist());
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() {
    return _fromPrimary((client) => client.fetchAlerts());
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) {
    return _fromPrimary(
      (client) =>
          client.reviewAlert(event: event, status: status, notes: notes),
    );
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() {
    return _fromPrimary((client) => client.fetchAuditEntries());
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) {
    return _fromPrimary((client) => client.simulateCommand(request));
  }
}

class UnavailableOperationsApiClient implements OperationsApiClient {
  const UnavailableOperationsApiClient();

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() async {
    return BackendIntegrationStatus.unavailable();
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() async {
    return SafetyChecklist.unavailable();
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() async {
    return const [];
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) async {
    throw StateError('Operations backend unavailable');
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() async {
    return const [];
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) async {
    throw StateError('Operations backend unavailable');
  }
}

FireDetectionEvent _alertFromJson(Map<String, dynamic> json) {
  return FireDetectionEvent(
    eventId: json['eventId'] as String? ?? '',
    detectionType: _detectionType(json['detectionType']),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    severity: _severity(json['severity']),
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0,
    sourceDroneId: json['sourceDroneId'] as String? ?? 'unknown',
    imagePlaceholder:
        json['thermalUri'] as String? ??
        json['imageUri'] as String? ??
        'backend alert frame',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ??
        DateTime.now().toUtc(),
    status: _alertStatus(json['status']),
    reviewer: json['reviewer'] as String?,
    reviewTimestamp: DateTime.tryParse(
      json['reviewTimestamp'] as String? ?? '',
    ),
    notes: json['notes'] as String? ?? '',
  );
}

AuditLogEntry _auditFromJson(Map<String, dynamic> json) {
  return AuditLogEntry(
    entryId: json['entryId'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ??
        DateTime.now().toUtc(),
    actor: json['actor'] as String? ?? 'backend',
    action: json['action'] as String? ?? '',
    targetId: json['targetId'] as String? ?? '',
    details: json['details'] as String? ?? '',
  );
}

DetectionType _detectionType(Object? value) {
  return switch (value?.toString().toLowerCase()) {
    'fire' => DetectionType.fire,
    _ => DetectionType.smoke,
  };
}

AlertSeverity _severity(Object? value) {
  return switch (value?.toString().toLowerCase()) {
    'low' => AlertSeverity.low,
    'high' => AlertSeverity.high,
    'critical' => AlertSeverity.critical,
    _ => AlertSeverity.medium,
  };
}

AlertStatus _alertStatus(Object? value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('false')) return AlertStatus.falsePositive;
  if (text.contains('resolved')) return AlertStatus.resolved;
  if (text.contains('confirmed')) return AlertStatus.confirmed;
  return AlertStatus.unconfirmed;
}

String _alertStatusLabel(AlertStatus status) {
  return switch (status) {
    AlertStatus.unconfirmed => 'Unconfirmed',
    AlertStatus.confirmed => 'Confirmed',
    AlertStatus.falsePositive => 'False Positive',
    AlertStatus.resolved => 'Resolved',
  };
}
