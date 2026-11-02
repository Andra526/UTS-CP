import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final ApiInterceptor interceptor = ApiInterceptor(TokenStorage.instance);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final headers = await interceptor.buildHeaders();
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return interceptor.handle(
        response,
        hadToken: headers.containsKey('Authorization'),
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi.');
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
      );
    }
  }
}
