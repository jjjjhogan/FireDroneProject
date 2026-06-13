import '../mock/simulation_fixtures.dart';
import '../models/command.dart';
import '../models/operations_enums.dart';
import '../models/safety_gate_status.dart';

class SafetyGateService {
  SafetyGateService({SafetyGateStatus? initialStatus})
    : _status =
          initialStatus ??
          const SafetyGateStatus(
            systemMode: SystemMode.simulation,
            hardwareEnabled: false,
            commandLocked: true,
            confirmationRequired: true,
            geofenceStatus: GeofenceStatus.simulatedValid,
            emergencyStopEngaged: false,
            statusMessage: 'Simulation command lock active',
          );

  SafetyGateStatus _status;

  SafetyGateStatus get status => _status;

  Future<CommandResult> submitCommand(CommandRequest request) async {
    final now = simulationBaseTime.add(const Duration(minutes: 2));
    if (request.commandType == DroneCommandType.emergencyStop) {
      _status = _status.copyWith(
        commandLocked: true,
        emergencyStopEngaged: true,
        statusMessage: 'Emergency stop engaged in simulation',
      );
      return CommandResult.accepted(
        request: request,
        message: 'Emergency stop engaged. Simulation command channel locked.',
        timestamp: now,
      );
    }

    if (_status.emergencyStopEngaged) {
      return CommandResult.blocked(
        request: request,
        reason: 'Emergency stop is engaged; simulated commands are locked.',
        timestamp: now,
      );
    }

    if (!request.confirmationProvided) {
      return CommandResult.blocked(
        request: request,
        reason: 'Operator confirmation is required for simulated commands.',
        timestamp: now,
      );
    }

    if (_status.hardwareEnabled) {
      return CommandResult.blocked(
        request: request,
        reason: 'Real hardware command dispatch is disabled for this MVP.',
        timestamp: now,
      );
    }

    return CommandResult.accepted(
      request: request,
      message: 'Simulated command accepted. No hardware command was sent.',
      timestamp: now,
    );
  }
}
