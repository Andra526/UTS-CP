import 'package:flutter/foundation.dart';

import '../../../shared/models/user_model.dart';

/// Menyimpan pengguna yang sedang login. Widget bisa mendengarkan perubahannya
/// (mis. nama diubah di Profil -> sapaan di Beranda ikut berubah).
class SessionController extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }
}

final SessionController session = SessionController();
