import 'package:flutter/material.dart';

import '../../features/admin_management/presentation/admin_home_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/dashboard/presentation/member_shell.dart';
import '../../features/dashboard/presentation/pt_dashboard_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String member = '/main';
  static const String trainer = '/pt';
  static const String admin = '/admin';

  /// Dipakai untuk logout otomatis saat token kedaluwarsa (401).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String homeFor(String role) {
    switch (role) {
      case Roles.trainer:
        return trainer;
      case Roles.admin:
        return admin;
      default:
        return member;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case login:
        page = const LoginScreen();
        break;
      case register:
        page = const RegisterScreen();
        break;
      case member:
        page = const MemberShell();
        break;
      case trainer:
        page = const PtDashboardScreen();
        break;
      case admin:
        page = const AdminHomeScreen();
        break;
      case splash:
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
