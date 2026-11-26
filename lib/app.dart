import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';

class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
