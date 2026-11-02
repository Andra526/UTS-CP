import '../helpers/json_utils.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? photoUrl;

  /// Admin: cabang yang dikelola.
  final String? managedGymId;

  /// Trainer: id profil trainer & cabang tempat bertugas.
  final String? trainerId;
  final String? trainerGymId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
    this.managedGymId,
    this.trainerId,
    this.trainerGymId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainerProfile'] is Map
        ? asMap(json['trainerProfile'])
        : null;
    return AppUser(
      id: asString(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asStringOrNull(json['phone']),
      role: asString(json['role'], 'MEMBER'),
      photoUrl: asStringOrNull(json['photoUrl']),
      managedGymId: asStringOrNull(json['managedGymId']),
      trainerId: trainer == null ? null : asStringOrNull(trainer['id']),
      trainerGymId: trainer == null ? null : asStringOrNull(trainer['gymId']),
    );
  }

  AppUser copyWith({String? name, String? phone, String? photoUrl}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      managedGymId: managedGymId,
      trainerId: trainerId,
      trainerGymId: trainerGymId,
    );
  }
}
