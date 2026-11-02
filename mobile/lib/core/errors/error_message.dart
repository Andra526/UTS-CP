import '../network/api_exception.dart';

/// Ubah error apa pun menjadi teks yang aman ditampilkan ke pengguna.
String errorMessage(Object? error) {
  if (error is ApiException) return error.message;
  return 'Terjadi kesalahan. Coba lagi.';
}
