import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/session_controller.dart';

class GymFitApp extends StatefulWidget {
  const GymFitApp({super.key});

  @override
  State<GymFitApp> createState() => _GymFitAppState();
}

class _GymFitAppState extends State<GymFitApp> {
  @override
  void initState() {
    super.initState();
    // Token ditolak server (kedaluwarsa) -> logout otomatis ke halaman login.
    ApiClient.instance.interceptor.onUnauthorized = () async {
      await TokenStorage.instance.clear();
      session.setUser(null);
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.login,
        (route) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
