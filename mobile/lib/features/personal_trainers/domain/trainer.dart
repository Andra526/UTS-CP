import '../../../shared/helpers/json_utils.dart';
import '../../bookings/domain/booking.dart';

class Trainer {
  final String id; // id profil trainer
  final String userId;
  final String name;
  final String? photoUrl;
  final String specialization;
  final int experienceYears;
  final String bio;
  final double rating;
  final int reviewsCount;
  final String gymId;
  final String gymName;

  const Trainer({
    required this.id,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.specialization,
    required this.experienceYears,
    required this.bio,
    required this.rating,
    required this.reviewsCount,
    required this.gymId,
    required this.gymName,
  });

  String get experienceLabel => '$experienceYears Tahun';

  factory Trainer.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user']);
    final gym = asMap(json['gym']);
    return Trainer(
      id: asString(json['id']),
      userId: asString(json['userId']),
      name: asString(user['name']),
      photoUrl: asStringOrNull(user['photoUrl']),
      specialization: asString(json['specialization']),
      experienceYears: asInt(json['experienceYears']),
      bio: asString(json['bio']),
      rating: asDouble(json['rating']),
      reviewsCount: asInt(json['reviewsCount']),
      gymId: asString(json['gymId'], asString(gym['id'])),
      gymName: asString(gym['name']),
    );
  }
}

class PtDashboard {
  final Trainer trainer;
  final int activeClients;
  final int pendingRequests;
  final int todaySessions;
  final double rating;
  final Booking? nextSession;

  const PtDashboard({
    required this.trainer,
    required this.activeClients,
    required this.pendingRequests,
    required this.todaySessions,
    required this.rating,
    required this.nextSession,
  });

  factory PtDashboard.fromJson(Map<String, dynamic> json) {
    final next = json['nextSession'];
    return PtDashboard(
      trainer: Trainer.fromJson(asMap(json['trainer'])),
      activeClients: asInt(json['activeClients']),
      pendingRequests: asInt(json['pendingRequests']),
      todaySessions: asInt(json['todaySessions']),
      rating: asDouble(json['rating']),
      nextSession: next is Map ? Booking.fromJson(asMap(next)) : null,
    );
  }
}
