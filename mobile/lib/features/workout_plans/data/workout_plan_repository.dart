import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/workout_plan.dart';

class WorkoutPlanRepository {
  final ApiClient _api = ApiClient.instance;

  /// Member: program milik akun yang login (server memakai token).
  Future<WorkoutPlan> mine() async {
    final data = await _api.get('/workout-plans/me');
    return WorkoutPlan.fromJson(asMap(data));
  }

  Future<void> markDone(String itemId) async {
    await _api.post('/workout-plans/me/$itemId/done');
  }

  Future<void> undoDone(String itemId) async {
    await _api.delete('/workout-plans/me/$itemId/done');
  }

  /// PT: program satu klien.
  Future<WorkoutPlan> forClient(String clientId) async {
    final data = await _api.get('/workout-plans/client/$clientId');
    return WorkoutPlan.fromJson(asMap(data));
  }

  Map<String, dynamic> _body({
    required String dayLabel,
    required String exercise,
    required int sets,
    required String reps,
    int? restSec,
    String note = '',
  }) => {
    'dayLabel': dayLabel,
    'exercise': exercise,
    'sets': sets,
    'reps': reps,
    if (restSec != null) 'restSec': restSec,
    'note': note,
  };

  Future<void> add(
    String clientId, {
    required String dayLabel,
    required String exercise,
    required int sets,
    required String reps,
    int? restSec,
    String note = '',
  }) async {
    await _api.post(
      '/workout-plans/client/$clientId',
      body: _body(
        dayLabel: dayLabel,
        exercise: exercise,
        sets: sets,
        reps: reps,
        restSec: restSec,
        note: note,
      ),
    );
  }

  Future<void> update(
    String id, {
    required String dayLabel,
    required String exercise,
    required int sets,
    required String reps,
    int? restSec,
    String note = '',
  }) async {
    await _api.patch(
      '/workout-plans/$id',
      body: _body(
        dayLabel: dayLabel,
        exercise: exercise,
        sets: sets,
        reps: reps,
        restSec: restSec,
        note: note,
      ),
    );
  }

  Future<void> remove(String id) async {
    await _api.delete('/workout-plans/$id');
  }
}
