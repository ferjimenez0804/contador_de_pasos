import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/body_data.dart';
import 'bmi_gauge.dart';
import 'brutal.dart';

class BodyDataControllers {
  final TextEditingController weightCtl;
  final TextEditingController heightCtl;
  final TextEditingController ageCtl;
  final TextEditingController goalCtl;
  String? sex; // 'M' o 'F'

  BodyDataControllers({
    int? weightKg,
    int? heightCm,
    int? age,
    this.sex,
    int dailyGoal = 10000,
  })  : weightCtl = TextEditingController(text: weightKg?.toString() ?? ''),
        heightCtl = TextEditingController(text: heightCm?.toString() ?? ''),
        ageCtl = TextEditingController(text: age?.toString() ?? ''),
        goalCtl = TextEditingController(text: dailyGoal.toString());

  int? get weightKg => int.tryParse(weightCtl.text.trim());
  int? get heightCm => int.tryParse(heightCtl.text.trim());
  int? get age => int.tryParse(ageCtl.text.trim());
  int? get dailyGoal => int.tryParse(goalCtl.text.trim());

  /// Solo llamar después de validar el formulario.
  BodyData toBodyData() => BodyData(
        weightKg: weightKg!.toDouble(),
        heightCm: heightCm!,
        age: age!,
        sex: sex!,
        dailyGoal: dailyGoal!,
      );

  void dispose() {
    weightCtl.dispose();
    heightCtl.dispose();
    ageCtl.dispose();
    goalCtl.dispose();
  }
}

/// Campos de peso, estatura, edad, sexo y meta diaria (solo números donde aplica).
/// Muestra una vista previa del IMC en cuanto peso y estatura son válidos.
class BodyDataFields extends StatelessWidget {
  final BodyDataControllers c;
  final VoidCallback onChanged;
  const BodyDataFields({super.key, required this.c, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final w = c.weightKg;
    final h = c.heightCm;
    final showBmi = w != null && h != null && w >= 30 && w <= 250 && h >= 100 && h <= 230;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BrutalField(
                controller: c.weightCtl,
                label: 'Peso kg',
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [Validators.digitsFormatter],
                maxLength: 3,
                onChanged: (_) => onChanged(),
                validator: (v) => Validators.integer(v, label: 'tu peso', min: 30, max: 250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrutalField(
                controller: c.heightCtl,
                label: 'Altura cm',
                icon: Icons.height_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [Validators.digitsFormatter],
                maxLength: 3,
                onChanged: (_) => onChanged(),
                validator: (v) => Validators.integer(v, label: 'tu estatura', min: 100, max: 230),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BrutalField(
                controller: c.ageCtl,
                label: 'Edad',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [Validators.digitsFormatter],
                maxLength: 3,
                validator: (v) => Validators.integer(v, label: 'tu edad', min: 10, max: 100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrutalField(
                controller: c.goalCtl,
                label: 'Meta pasos',
                icon: Icons.flag_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [Validators.digitsFormatter],
                maxLength: 5,
                validator: (v) => Validators.integer(v, label: 'tu meta', min: 1000, max: 50000),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormField<String>(
          validator: (_) => c.sex == null ? 'Selecciona tu sexo' : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceBlock(
                      label: 'Masculino',
                      icon: Icons.male_rounded,
                      selected: c.sex == 'M',
                      color: AppColors.cobalt,
                      onTap: () {
                        c.sex = 'M';
                        state.didChange(c.sex);
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceBlock(
                      label: 'Femenino',
                      icon: Icons.female_rounded,
                      selected: c.sex == 'F',
                      color: AppColors.lilac,
                      onTap: () {
                        c.sex = 'F';
                        state.didChange(c.sex);
                        onChanged();
                      },
                    ),
                  ),
                ],
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(state.errorText!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        if (showBmi) ...[
          const SizedBox(height: 18),
          BrutalBox(color: AppColors.card, child: BmiGauge(weightKg: w!.toDouble(), heightCm: h!)),
        ],
      ],
    );
  }
}
