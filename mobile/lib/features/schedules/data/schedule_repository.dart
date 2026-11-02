import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/schedule_slot.dart';

class ScheduleRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<ScheduleSlot>> mine() async {
    final data = await _api.get('/trainer-schedules/me');
    return asList(data).map((e) => ScheduleSlot.fromJson(asMap(e))).toList();
  }

  Future<List<ScheduleSlot>> byTrainer(String trainerId) async {
    final data = await _api.get(
      '/trainer-schedules',
      query: {'trainerId': trainerId},
    );
    return asList(data).map((e) => ScheduleSlot.fromJson(asMap(e))).toList();
  }

  Future<ScheduleSlot> create({
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final data = await _api.post(
      '/trainer-schedules',
      body: {'day': day, 'startTime': startTime, 'endTime': endTime},
    );
    return ScheduleSlot.fromJson(asMap(data));
  }

  Future<void> remove(String id) async {
    await _api.delete('/trainer-schedules/$id');
  }
}
