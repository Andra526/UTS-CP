import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/helpers/json_utils.dart';
import '../../../shared/models/user_model.dart';
import '../presentation/session_controller.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  Future<AppUser> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {'identifier': identifier.trim(), 'password': password},
    );
    return _persist(asMap(data));
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role, // MEMBER | TRAINER
    String? phone,
    String? gymId,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (gymId != null) 'gymId': gymId,
      },
    );
    return _persist(asMap(data));
  }

  /// Mengembalikan user jika token tersimpan masih valid, selain itu null.
  Future<AppUser?> restore() async {
    final token = await TokenStorage.instance.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.get('/auth/me');
      final user = AppUser.fromJson(asMap(data));
      session.setUser(user);
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await TokenStorage.instance.clear();
        session.setUser(null);
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    session.setUser(null);
  }

  Future<AppUser> _persist(Map<String, dynamic> data) async {
    await TokenStorage.instance.saveToken(asString(data['accessToken']));
    final user = AppUser.fromJson(asMap(data['user']));
    session.setUser(user);
    return user;
  }
}
