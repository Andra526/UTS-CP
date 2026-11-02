import '../../../shared/helpers/json_utils.dart';

class Booking {
  final String id;
  final String status;
  final DateTime scheduledAt;
  final int durationMin;
  final String note;
  final String goalType;
  final String customGoal;

  final String clientId;
  final String clientName;
  final String? clientPhoto;

  final String trainerId;
  final String trainerName;
  final String? trainerPhoto;

  final bool hasReport;

  const Booking({
    required this.id,
    required this.status,
    required this.scheduledAt,
    required this.durationMin,
    required this.note,
    required this.goalType,
    required this.customGoal,
    required this.clientId,
    required this.clientName,
    required this.clientPhoto,
    required this.trainerId,
    required this.trainerName,
    required this.trainerPhoto,
    required this.hasReport,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final client = asMap(json['client']);
    final trainer = asMap(json['trainer']);
    final trainerUser = asMap(trainer['user']);
    return Booking(
      id: asString(json['id']),
      status: asString(json['status']),
      scheduledAt: asDate(json['scheduledAt']),
      durationMin: asInt(json['durationMin'], 60),
      note: asString(json['note']),
      goalType: asString(json['goalType'], 'GENERAL'),
      customGoal: asString(json['customGoal']),
      clientId: asString(client['id'], asString(json['clientId'])),
      clientName: asString(client['name']),
      clientPhoto: asStringOrNull(client['photoUrl']),
      trainerId: asString(trainer['id'], asString(json['trainerId'])),
      trainerName: asString(trainerUser['name']),
      trainerPhoto: asStringOrNull(trainerUser['photoUrl']),
      hasReport: json['session'] is Map,
    );
  }
}
