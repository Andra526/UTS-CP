import '../../../shared/helpers/json_utils.dart';

class TrainingSession {
  final String id;
  final String attendance;
  final int intensity;
  final String notes;
  final DateTime completedAt;
  final DateTime scheduledAt;
  final int durationMin;
  final String clientName;
  final String trainerName;

  const TrainingSession({
    required this.id,
    required this.attendance,
    required this.intensity,
    required this.notes,
    required this.completedAt,
    required this.scheduledAt,
    required this.durationMin,
    required this.clientName,
    required this.trainerName,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final booking = asMap(json['booking']);
    final client = asMap(booking['client']);
    final trainer = asMap(booking['trainer']);
    final trainerUser = asMap(trainer['user']);
    return TrainingSession(
      id: asString(json['id']),
      attendance: asString(json['attendance']),
      intensity: asInt(json['intensity']),
      notes: asString(json['notes']),
      completedAt: asDate(json['completedAt']),
      scheduledAt: asDate(booking['scheduledAt']),
      durationMin: asInt(booking['durationMin'], 60),
      clientName: asString(client['name']),
      trainerName: asString(trainerUser['name']),
    );
  }

  String get attendanceLabel {
    switch (attendance) {
      case 'HADIR':
        return 'Hadir';
      case 'TERLAMBAT':
        return 'Terlambat';
      case 'TIDAK_HADIR':
        return 'Tidak Hadir';
      default:
        return attendance;
    }
  }
}
