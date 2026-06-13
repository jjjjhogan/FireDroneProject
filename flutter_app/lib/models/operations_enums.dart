enum SystemMode { simulation, liveReadOnly, hardwareDisabled }

enum DetectionType { fire, smoke }

enum AlertSeverity { low, medium, high, critical }

enum AlertStatus { unconfirmed, confirmed, falsePositive, resolved }

enum DroneCommandType {
  arm,
  takeoff,
  land,
  rtl,
  start,
  pause,
  stop,
  emergencyStop,
}

enum LinkStatus { simulated, stable, degraded, offline, notConfigured }

enum MissionStatus { planning, active, paused, complete, blocked }

enum ScenarioDifficulty { basic, intermediate, advanced, extreme }

enum GeofenceStatus { simulatedValid, unknown, invalid, disabled }

extension SystemModeLabel on SystemMode {
  String get label {
    return switch (this) {
      SystemMode.simulation => 'Simulation',
      SystemMode.liveReadOnly => 'Live read-only',
      SystemMode.hardwareDisabled => 'Hardware disabled',
    };
  }
}

extension DetectionTypeLabel on DetectionType {
  String get label {
    return switch (this) {
      DetectionType.fire => 'Fire',
      DetectionType.smoke => 'Smoke',
    };
  }
}

extension AlertSeverityLabel on AlertSeverity {
  String get label {
    return switch (this) {
      AlertSeverity.low => 'Low',
      AlertSeverity.medium => 'Medium',
      AlertSeverity.high => 'High',
      AlertSeverity.critical => 'Critical',
    };
  }
}

extension AlertStatusLabel on AlertStatus {
  String get label {
    return switch (this) {
      AlertStatus.unconfirmed => 'Unconfirmed',
      AlertStatus.confirmed => 'Confirmed',
      AlertStatus.falsePositive => 'False positive',
      AlertStatus.resolved => 'Resolved',
    };
  }
}

extension DroneCommandTypeLabel on DroneCommandType {
  String get label {
    return switch (this) {
      DroneCommandType.arm => 'Arm',
      DroneCommandType.takeoff => 'Takeoff',
      DroneCommandType.land => 'Land',
      DroneCommandType.rtl => 'RTL',
      DroneCommandType.start => 'Start',
      DroneCommandType.pause => 'Pause',
      DroneCommandType.stop => 'Stop',
      DroneCommandType.emergencyStop => 'Emergency Stop',
    };
  }
}

extension LinkStatusLabel on LinkStatus {
  String get label {
    return switch (this) {
      LinkStatus.simulated => 'Simulated',
      LinkStatus.stable => 'Stable',
      LinkStatus.degraded => 'Degraded',
      LinkStatus.offline => 'Offline',
      LinkStatus.notConfigured => 'Not configured',
    };
  }
}

extension MissionStatusLabel on MissionStatus {
  String get label {
    return switch (this) {
      MissionStatus.planning => 'Planning',
      MissionStatus.active => 'Active',
      MissionStatus.paused => 'Paused',
      MissionStatus.complete => 'Complete',
      MissionStatus.blocked => 'Blocked',
    };
  }
}

extension ScenarioDifficultyLabel on ScenarioDifficulty {
  String get label {
    return switch (this) {
      ScenarioDifficulty.basic => 'Basic',
      ScenarioDifficulty.intermediate => 'Intermediate',
      ScenarioDifficulty.advanced => 'Advanced',
      ScenarioDifficulty.extreme => 'Extreme',
    };
  }
}

extension GeofenceStatusLabel on GeofenceStatus {
  String get label {
    return switch (this) {
      GeofenceStatus.simulatedValid => 'Simulated valid',
      GeofenceStatus.unknown => 'Unknown',
      GeofenceStatus.invalid => 'Invalid',
      GeofenceStatus.disabled => 'Disabled',
    };
  }
}
