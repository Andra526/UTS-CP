import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Menambahkan header (token) pada request dan menerjemahkan response.
class ApiInterceptor {
  ApiInterceptor(this._storage);

  final TokenStorage _storage;

  /// Dipanggil saat server menolak token (401) pada request yang membawa token.
  void Function()? onUnauthorized;

  Future<Map<String, String>> buildHeaders() async {
    final token = await _storage.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Mengembalikan body JSON (Map/List/null) atau melempar [ApiException].
  dynamic handle(http.Response response, {required bool hadToken}) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;

    if (status == 401 && hadToken) {
      onUnauthorized?.call();
    }
    throw ApiException(_extractMessage(decoded, status), statusCode: status);
  }

  String _extractMessage(dynamic decoded, int status) {
    if (decoded is Map && decoded['message'] != null) {
      final m = decoded['message'];
      if (m is List) return m.map((e) => e.toString()).join('\n');
      return m.toString();
    }
    if (status == 401) return 'Sesi berakhir. Silakan login kembali.';
    if (status == 403) return 'Anda tidak punya akses.';
    if (status == 404) return 'Data tidak ditemukan.';
    if (status >= 500) return 'Server sedang bermasalah.';
    return 'Permintaan gagal ($status).';
  }
}
