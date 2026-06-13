import 'operations_enums.dart';

class CommandRequest {
  const CommandRequest({
    required this.requestId,
    required this.commandType,
    required this.requestedBy,
    required this.targetDroneId,
    required this.timestamp,
    required this.confirmationProvided,
    required this.notes,
  });

  final String requestId;
  final DroneCommandType commandType;
  final String requestedBy;
  final String targetDroneId;
  final DateTime timestamp;
  final bool confirmationProvided;
  final String notes;

  CommandRequest copyWith({
    DroneCommandType? commandType,
    bool? confirmationProvided,
    String? notes,
  }) {
    return CommandRequest(
      requestId: requestId,
      commandType: commandType ?? this.commandType,
      requestedBy: requestedBy,
      targetDroneId: targetDroneId,
      timestamp: timestamp,
      confirmationProvided: confirmationProvided ?? this.confirmationProvided,
      notes: notes ?? this.notes,
    );
  }
}

class CommandResult {
  const CommandResult({
    required this.accepted,
    required this.commandType,
    required this.targetDroneId,
    required this.message,
    required this.timestamp,
    this.blockedReason,
  });

  factory CommandResult.accepted({
    required CommandRequest request,
    required String message,
    required DateTime timestamp,
  }) {
    return CommandResult(
      accepted: true,
      commandType: request.commandType,
      targetDroneId: request.targetDroneId,
      message: message,
      timestamp: timestamp,
    );
  }

  factory CommandResult.blocked({
    required CommandRequest request,
    required String reason,
    required DateTime timestamp,
  }) {
    return CommandResult(
      accepted: false,
      commandType: request.commandType,
      targetDroneId: request.targetDroneId,
      message: reason,
      blockedReason: reason,
      timestamp: timestamp,
    );
  }

  final bool accepted;
  final DroneCommandType commandType;
  final String targetDroneId;
  final String message;
  final String? blockedReason;
  final DateTime timestamp;
}
