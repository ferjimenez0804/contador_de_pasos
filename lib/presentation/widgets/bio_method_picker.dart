import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/biometric_service.dart';
import '../../domain/entities/bio_method.dart';
import 'brutal.dart';

/// Selector Huella / Rostro. Los métodos que el equipo no ofrece se deshabilitan.
class BioMethodPicker extends StatelessWidget {
  final BioCapabilities caps;
  final BioMethod selected;
  final ValueChanged<BioMethod> onSelect;
  const BioMethodPicker({
    super.key,
    required this.caps,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceBlock(
                label: 'Huella',
                icon: bioIcon(BioMethod.fingerprint),
                selected: selected == BioMethod.fingerprint,
                enabled: caps.fingerprint,
                color: AppColors.mint,
                onTap: () => onSelect(BioMethod.fingerprint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceBlock(
                label: 'Rostro',
                icon: bioIcon(BioMethod.face),
                selected: selected == BioMethod.face,
                enabled: caps.face,
                color: AppColors.lilac,
                onTap: () => onSelect(BioMethod.face),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          caps.any
              ? 'Android muestra el sensor que tengas registrado en Ajustes > Seguridad.'
              : 'Este equipo no tiene huella ni rostro registrados.',
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
