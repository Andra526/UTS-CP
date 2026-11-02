import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../data/auth_repository.dart';

/// Hapus sesi lalu kembali ke halaman login (riwayat navigasi dibersihkan).
Future<void> performLogout(BuildContext context) async {
  final navigator = Navigator.of(context);
  await AuthRepository().logout();
  navigator.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
}
