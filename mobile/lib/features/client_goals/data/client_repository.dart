import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/client_goal.dart';

class ClientRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<PtClient>> mine() async {
    final data = await _api.get('/clients');
    return asList(data).map((e) => PtClient.fromJson(asMap(e))).toList();
  }

  /// PT menetapkan target program + target nutrisi klien.
  Future<ClientGoal> saveGoal(
    String clientId, {
    required String description,
    int? targetCalories,
    int? targetProtein,
  }) async {
    final data = await _api.put(
      '/client-goals/$clientId',
      body: {
        'description': description,
        if (targetCalories != null) 'targetCalories': targetCalories,
        if (targetProtein != null) 'targetProtein': targetProtein,
      },
    );
    return ClientGoal.fromJson(asMap(data));
  }
}
