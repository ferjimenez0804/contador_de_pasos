import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

const String _letters = 'a-zA-ZáéíóúÁÉÍÓÚñÑüÜ';

/// Evalúa los requisitos de una contraseña y su nivel de seguridad.
class PasswordCheck {
  final String password;
  const PasswordCheck(this.password);

  bool get hasLength => password.length >= 8;
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLower => RegExp(r'[a-z]').hasMatch(password);
  bool get hasDigit => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSymbol =>
      RegExp(r'[^A-Za-z0-9\sáéíóúÁÉÍÓÚñÑüÜ]').hasMatch(password);

  int get met =>
      [hasLength, hasUpper, hasLower, hasDigit, hasSymbol].where((e) => e).length;

  bool get valid => met == 5;
  bool get veryStrong => valid && password.length >= 12;

  String get label {
    if (password.isEmpty) return 'Escribe tu contraseña';
    if (veryStrong) return 'Muy fuerte';
    if (valid) return 'Fuerte';
    if (met == 4) return 'Media';
    if (met == 3) return 'Débil';
    return 'Muy débil';
  }

  Color get color {
    if (password.isEmpty) return AppColors.card;
    if (valid) return AppColors.lime;
    if (met == 4) return AppColors.sun;
    if (met == 3) return AppColors.coral;
    return AppColors.danger;
  }
}

class Validators {
  // ---- Formateadores: bloquean caracteres inválidos mientras se escribe
  static final TextInputFormatter nameFormatter =
      FilteringTextInputFormatter.allow(RegExp('[$_letters ]'));
  static final TextInputFormatter usernameFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'));
  static final TextInputFormatter digitsFormatter =
      FilteringTextInputFormatter.digitsOnly;
  static final TextInputFormatter noSpaceFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  // ---- Validadores
  static String? name(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa tu nombre';
    if (!RegExp('^[$_letters]+( [$_letters]+)*\$').hasMatch(t)) {
      return 'Solo letras, con un espacio entre palabras';
    }
    if (t.length < 3) return 'Mínimo 3 letras';
    return null;
  }

  static String? username(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa un usuario';
    if (t.length < 4) return 'Mínimo 4 caracteres';
    if (t.length > 20) return 'Máximo 20 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(t)) {
      return 'Solo letras, números y guion bajo';
    }
    return null;
  }

  static String? integer(String? v,
      {required String label, required int min, required int max}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa $label';
    final n = int.tryParse(t);
    if (n == null) return 'Solo números';
    if (n < min || n > max) return 'Entre $min y $max';
    return null;
  }

  static String? password(String? v) {
    final p = v ?? '';
    if (p.isEmpty) return 'Ingresa una contraseña';
    if (!PasswordCheck(p).valid) return 'No cumple todos los requisitos';
    return null;
  }
}
