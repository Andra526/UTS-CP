import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/membership.dart';

class MembershipRepository {
  final ApiClient _api = ApiClient.instance;

  /// Membership aktif (masa berlaku terpanjang) atau null.
  Future<Membership?> active() async {
    final data = asMap(await _api.get('/memberships/me/active'));
    final active = data['active'];
    if (active is Map) return Membership.fromJson(asMap(active));
    return null;
  }

  Future<List<Membership>> mine() async {
    final data = await _api.get('/memberships/me');
    return asList(data).map((e) => Membership.fromJson(asMap(e))).toList();
  }

  /// Pembayaran masih simulasi di backend (langsung berhasil).
  Future<Membership> purchase(String planId) async {
    final data = await _api.post('/memberships', body: {'planId': planId});
    return Membership.fromJson(asMap(data));
  }
}
