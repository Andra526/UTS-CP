import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';
import '../../authentication/presentation/session_controller.dart';

class ProfileRepository {
  final ApiClient _api = ApiClient.instance;

  /// Ubah nama / nomor HP, lalu perbarui sesi agar seluruh layar ikut berubah.
  Future<AppUser> updateMe({String? name, String? phone}) async {
    final data = await _api.patch(
      '/users/me',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      },
    );
    final updated = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    final current = session.user;
    session.setUser(
      current == null
          ? updated
          : current.copyWith(name: updated.name, phone: updated.phone),
    );
    return updated;
  }
}
