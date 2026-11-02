import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
  );
}
