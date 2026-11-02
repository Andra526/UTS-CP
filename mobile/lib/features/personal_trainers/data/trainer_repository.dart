import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/trainer.dart';

class TrainerRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<Trainer>> list({String? gymId}) async {
    final data = await _api.get(
      '/trainers',
      query: gymId == null ? null : {'gymId': gymId},
    );
    return asList(data).map((e) => Trainer.fromJson(asMap(e))).toList();
  }

  Future<Trainer> me() async {
    final data = await _api.get('/trainers/me');
    return Trainer.fromJson(asMap(data));
  }

  Future<PtDashboard> dashboard() async {
    final data = await _api.get('/trainers/me/dashboard');
    return PtDashboard.fromJson(asMap(data));
  }
}
