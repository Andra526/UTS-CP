import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/training_session.dart';

class TrainingSessionRepository {
  final ApiClient _api = ApiClient.instance;

  /// Laporan sesi dari PT; booking otomatis menjadi COMPLETED.
  Future<TrainingSession> create({
    required String bookingId,
    required String attendance, // HADIR | TERLAMBAT | TIDAK_HADIR
    required int intensity,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/training-sessions',
      body: {
        'bookingId': bookingId,
        'attendance': attendance,
        'intensity': intensity,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return TrainingSession.fromJson(asMap(data));
  }

  /// Riwayat latihan member.
  Future<List<TrainingSession>> mine() async {
    final data = await _api.get('/training-sessions/me');
    return asList(data).map((e) => TrainingSession.fromJson(asMap(e))).toList();
  }
}
