class AuditLogEntry {
  const AuditLogEntry({
    required this.entryId,
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.targetId,
    required this.details,
  });

  final String entryId;
  final DateTime timestamp;
  final String actor;
  final String action;
  final String targetId;
  final String details;
}
