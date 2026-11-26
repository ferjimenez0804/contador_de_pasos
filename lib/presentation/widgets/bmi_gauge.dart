import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bmi.dart';
import 'brutal.dart';

/// Medidor del IMC en bloques de color con indicador.
class BmiGauge extends StatelessWidget {
  final double weightKg;
  final int heightCm;
  const BmiGauge({super.key, required this.weightKg, required this.heightCm});

  static const double _min = 15, _max = 40;

  @override
  Widget build(BuildContext context) {
    final bmi = calcBmi(weightKg, heightCm);
    final info = bmiInfo(bmi);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('IMC ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(bmi.toStringAsFixed(1),
                style: const TextStyle(
                    fontFamily: AppTheme.mono, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            const Spacer(),
            Tag(info.label, color: info.color),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, cons) {
          final w = cons.maxWidth;
          final x = ((bmi.clamp(_min, _max) - _min) / (_max - _min)) * w;
          return SizedBox(
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 16,
                  height: 24,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: brutalDecoration(color: AppColors.card, shadow: 0, radius: 4),
                    child: const Row(
                      children: [
                        _Seg(35, AppColors.cobalt),
                        _Seg(65, AppColors.lime),
                        _Seg(50, AppColors.sun),
                        _Seg(100, AppColors.coral, last: true),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (x - 14).clamp(-6.0, w - 22),
                  top: -6,
                  child: const Icon(Icons.arrow_drop_down_rounded, size: 30, color: AppColors.ink),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Num('15'),
            _Num('18.5'),
            _Num('25'),
            _Num('30'),
            _Num('40'),
          ],
        ),
        const SizedBox(height: 8),
        Text(info.tip, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        const Text('Referencia OMS, no es un diagnóstico.',
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  final int flex;
  final Color color;
  final bool last;
  const _Seg(this.flex, this.color, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: last ? null : const Border(right: BorderSide(color: AppColors.ink, width: 2)),
        ),
      ),
    );
  }
}

class _Num extends StatelessWidget {
  final String t;
  const _Num(this.t);

  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(fontFamily: AppTheme.mono, fontSize: 10, fontWeight: FontWeight.w700));
}
