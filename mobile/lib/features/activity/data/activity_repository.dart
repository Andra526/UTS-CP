import '../../../core/network/api_client.dart';
import '../../../shared/helpers/json_utils.dart';
import '../domain/activity.dart';

class ActivityRepository {
  final ApiClient _api = ApiClient.instance;

  /// Log aktivitas milik akun yang login.
  Future<ActivityLog> mine() async {
    final data = await _api.get('/activity/me');
    return ActivityLog.fromJson(asMap(data));
  }
}
