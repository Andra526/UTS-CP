import 'package:flutter/foundation.dart';

/// Alamat backend. Ubah lewat:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
/// (wajib dipakai jika menjalankan di HP asli).
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Emulator Android mengakses komputer host lewat 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static const Duration timeout = Duration(seconds: 15);
}
