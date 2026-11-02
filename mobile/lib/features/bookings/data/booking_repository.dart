import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/booking.dart';

class BookingRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Booking> create({
    required String trainerId,
    required DateTime scheduledAt,
    int durationMin = 60,
    String note = '',
    String goalType = 'GENERAL',
    String customGoal = '',
  }) async {
    final data = await _api.post(
      '/bookings',
      body: {
        'trainerId': trainerId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'durationMin': durationMin,
        'goalType': goalType,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        if (customGoal.trim().isNotEmpty) 'customGoal': customGoal.trim(),
      },
    );
    return Booking.fromJson(asMap(data));
  }

  /// PT menjadwalkan sesi (hari + jam) untuk kliennya; langsung ACCEPTED.
  Future<Booking> scheduleByTrainer({
    required String clientId,
    required DateTime scheduledAt,
    int durationMin = 60,
    String note = '',
  }) async {
    final data = await _api.post(
      '/bookings/trainer/schedule',
      body: {
        'clientId': clientId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'durationMin': durationMin,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return Booking.fromJson(asMap(data));
  }

  /// Booking milik member yang login.
  Future<List<Booking>> mine() async {
    final data = await _api.get('/bookings/me');
    return asList(data).map((e) => Booking.fromJson(asMap(e))).toList();
  }

  /// Booking untuk PT yang login (opsional filter status).
  Future<List<Booking>> forTrainer({String? status}) async {
    final data = await _api.get(
      '/bookings/trainer',
      query: status == null ? null : {'status': status},
    );
    return asList(data).map((e) => Booking.fromJson(asMap(e))).toList();
  }

  Future<Booking> respond(String id, {required bool accept}) async {
    final data = await _api.patch(
      '/bookings/$id/status',
      body: {'status': accept ? 'ACCEPTED' : 'REJECTED'},
    );
    return Booking.fromJson(asMap(data));
  }

  Future<Booking> cancel(String id) async {
    final data = await _api.patch('/bookings/$id/cancel');
    return Booking.fromJson(asMap(data));
  }
}
