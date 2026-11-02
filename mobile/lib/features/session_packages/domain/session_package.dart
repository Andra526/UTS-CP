import '../../../shared/helpers/json_utils.dart';

/// Kuota sesi satu pasangan klien-PT (default 8 sesi untuk semua PT).
class SessionPackage {
  final String trainerId;
  final String trainerName;
  final int total;
  final int used; // sesi selesai
  final int reserved; // sesi menunggu/terjadwal
  final int remaining; // "Sisa sesi" = total - used
  final int available; // masih boleh booking berapa lagi

  const SessionPackage({
    required this.trainerId,
    required this.trainerName,
    required this.total,
    required this.used,
    required this.reserved,
    required this.remaining,
    required this.available,
  });

  factory SessionPackage.fromJson(Map<String, dynamic> json) => SessionPackage(
    trainerId: asString(json['trainerId']),
    trainerName: asString(json['trainerName']),
    total: asInt(json['total'], 8),
    used: asInt(json['used']),
    reserved: asInt(json['reserved']),
    remaining: asInt(json['remaining']),
    available: asInt(json['available']),
  );

  bool get isExhausted => remaining <= 0;
  bool get canBook => available > 0;
  double get progress => total <= 0 ? 0 : (used / total).clamp(0.0, 1.0).toDouble();
}
