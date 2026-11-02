import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/session_package.dart';

class SessionPackageRepository {
  final ApiClient _api = ApiClient.instance;

  /// Member: semua kuota sesi miliknya (satu per PT).
  Future<List<SessionPackage>> mine() async {
    final data = await _api.get('/session-packages/me');
    return asList(asMap(data)['items']).map((e) => SessionPackage.fromJson(asMap(e))).toList();
  }

  /// Member: kuota dengan satu PT tertentu (belum ada paket = 8 sesi penuh).
  Future<SessionPackage> withTrainer(String trainerId) async {
    final data = await _api.get('/session-packages/me/trainer/$trainerId');
    return SessionPackage.fromJson(asMap(data));
  }

  /// PT: kuota salah satu kliennya.
  Future<SessionPackage> forClient(String clientId) async {
    final data = await _api.get('/session-packages/client/$clientId');
    return SessionPackage.fromJson(asMap(data));
  }

  /// PT: tambah kuota klien.
  Future<SessionPackage> addQuota(String clientId, int amount) async {
    final data = await _api.post(
      '/session-packages/client/$clientId/add',
      body: {'amount': amount},
    );
    return SessionPackage.fromJson(asMap(data));
  }
}
