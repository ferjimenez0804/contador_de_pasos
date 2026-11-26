import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import 'brutal.dart';

/// Medidor de seguridad en 5 bloques + lista de requisitos.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final c = PasswordCheck(password);
    final reqs = [
      ('8+ caracteres', c.hasLength),
      ('Mayúscula', c.hasUpper),
      ('Minúscula', c.hasLower),
      ('Número', c.hasDigit),
      ('Símbolo', c.hasSymbol),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 14,
                  decoration: brutalDecoration(
                    color: i < c.met ? c.color : AppColors.card,
                    shadow: 0,
                    radius: 3,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(c.label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in reqs)
              Tag(
                r.$1,
                color: r.$2 ? AppColors.lime : AppColors.card,
                icon: r.$2 ? Icons.check_rounded : Icons.close_rounded,
              ),
          ],
        ),
      ],
    );
  }
}
