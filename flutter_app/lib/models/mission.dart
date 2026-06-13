import 'operations_enums.dart';

class Mission {
  const Mission({
    required this.missionId,
    required this.name,
    required this.area,
    required this.assignedDroneId,
    required this.operatorName,
    required this.status,
    required this.startTime,
    required this.lastUpdateTime,
    required this.notes,
  });

  final String missionId;
  final String name;
  final String area;
  final String assignedDroneId;
  final String operatorName;
  final MissionStatus status;
  final DateTime startTime;
  final DateTime lastUpdateTime;
  final String notes;
}
