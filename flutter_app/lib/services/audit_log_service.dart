import '../mock/simulation_fixtures.dart';
import '../models/audit_log_entry.dart';

abstract class AuditLogService {
  Future<List<AuditLogEntry>> entries();

  Future<AuditLogEntry> record({
    required String actor,
    required String action,
    required String targetId,
    required String details,
  });
}

class InMemoryAuditLogService implements AuditLogService {
  InMemoryAuditLogService({DateTime? clock})
    : _baseTime = clock ?? simulationBaseTime;

  final DateTime _baseTime;
  final List<AuditLogEntry> _entries = [];

  @override
  Future<List<AuditLogEntry>> entries() async {
    return List.unmodifiable(_entries.reversed);
  }

  @override
  Future<AuditLogEntry> record({
    required String actor,
    required String action,
    required String targetId,
    required String details,
  }) async {
    final entry = AuditLogEntry(
      entryId: 'audit-${_entries.length + 1}',
      timestamp: _baseTime.add(Duration(seconds: _entries.length)),
      actor: actor,
      action: action,
      targetId: targetId,
      details: details,
    );
    _entries.add(entry);
    return entry;
  }
}
