import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/meal_plan.dart';

class MealPlanRepository {
  final ApiClient _api = ApiClient.instance;

  /// Member: pola makan milik akun yang sedang login (server memakai token,
  /// jadi tidak mungkin mengambil punya orang lain).
  Future<MealPlan> mine() async {
    final data = await _api.get('/meal-plans/me');
    return MealPlan.fromJson(asMap(data));
  }

  /// PT: pola makan satu klien.
  Future<MealPlan> forClient(String clientId) async {
    final data = await _api.get('/meal-plans/client/$clientId');
    return MealPlan.fromJson(asMap(data));
  }

  Map<String, dynamic> _body({
    required String time,
    required String category,
    required String description,
    required int calories,
    required int protein,
  }) => {
    'time': time,
    'category': category,
    'description': description,
    'calories': calories,
    'protein': protein,
  };

  Future<void> add(
    String clientId, {
    required String time,
    required String category,
    required String description,
    required int calories,
    required int protein,
  }) async {
    await _api.post(
      '/meal-plans/client/$clientId',
      body: _body(
        time: time,
        category: category,
        description: description,
        calories: calories,
        protein: protein,
      ),
    );
  }

  Future<void> update(
    String id, {
    required String time,
    required String category,
    required String description,
    required int calories,
    required int protein,
  }) async {
    await _api.patch(
      '/meal-plans/$id',
      body: _body(
        time: time,
        category: category,
        description: description,
        calories: calories,
        protein: protein,
      ),
    );
  }

  Future<void> remove(String id) async {
    await _api.delete('/meal-plans/$id');
  }
}
