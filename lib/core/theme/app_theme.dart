import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  /// Fuente monoespaciada del sistema para cifras (tipo marcador deportivo).
  static const String mono = 'monospace';

  static ThemeData get light => dark;

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cobalt,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: NoSplash.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.lime,
        selectionHandleColor: AppColors.ink,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}
