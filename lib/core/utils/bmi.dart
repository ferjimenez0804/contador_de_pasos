import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BmiInfo {
  final String label;
  final Color color;
  final String tip;
  const BmiInfo(this.label, this.color, this.tip);
}

double calcBmi(double weightKg, int heightCm) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

/// Clasificación de la OMS (referencia orientativa, no es un diagnóstico).
BmiInfo bmiInfo(double bmi) {
  if (bmi < 18.5) {
    return const BmiInfo('Bajo peso', AppColors.cobalt,
        'Tu peso está por debajo del rango saludable. Cuida tu alimentación y descanso.');
  }
  if (bmi < 25) {
    return const BmiInfo('Peso normal', AppColors.lime,
        '¡Excelente! Tu peso está en el rango saludable. Mantén tu actividad.');
  }
  if (bmi < 30) {
    return const BmiInfo('Sobrepeso', AppColors.sun,
        'Estás por encima del rango saludable. Caminar a diario te ayuda.');
  }
  return const BmiInfo('Obesidad', AppColors.coral,
      'Tu peso está muy por encima del rango saludable. Consulta a un profesional.');
}
