import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/gym.dart';

class GymRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<Gym>> list() async {
    final data = await _api.get('/gyms');
    return asList(data).map((e) => Gym.fromJson(asMap(e))).toList();
  }

  Future<Gym> get(String id) async {
    final data = await _api.get('/gyms/$id');
    return Gym.fromJson(asMap(data));
  }

  /// Khusus Admin Gym: ubah info cabang yang dikelola.
  Future<Gym> update(
    String id, {
    String? address,
    String? openHours,
    String? phone,
  }) async {
    final data = await _api.patch(
      '/gyms/$id',
      body: {
        if (address != null) 'address': address,
        if (openHours != null) 'openHours': openHours,
        if (phone != null) 'phone': phone,
      },
    );
    return Gym.fromJson(asMap(data));
  }
}
