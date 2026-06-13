import 'operations_enums.dart';

class SafetyGateStatus {
  const SafetyGateStatus({
    required this.systemMode,
    required this.hardwareEnabled,
    required this.commandLocked,
    required this.confirmationRequired,
    required this.geofenceStatus,
    required this.emergencyStopEngaged,
    required this.statusMessage,
  });

  final SystemMode systemMode;
  final bool hardwareEnabled;
  final bool commandLocked;
  final bool confirmationRequired;
  final GeofenceStatus geofenceStatus;
  final bool emergencyStopEngaged;
  final String statusMessage;

  bool get realHardwareDisabled => !hardwareEnabled;

  SafetyGateStatus copyWith({
    bool? commandLocked,
    bool? confirmationRequired,
    GeofenceStatus? geofenceStatus,
    bool? emergencyStopEngaged,
    String? statusMessage,
  }) {
    return SafetyGateStatus(
      systemMode: systemMode,
      hardwareEnabled: hardwareEnabled,
      commandLocked: commandLocked ?? this.commandLocked,
      confirmationRequired: confirmationRequired ?? this.confirmationRequired,
      geofenceStatus: geofenceStatus ?? this.geofenceStatus,
      emergencyStopEngaged: emergencyStopEngaged ?? this.emergencyStopEngaged,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
