import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'brutal.dart';

/// Gráfica de área con trazo de tinta (sin dependencias externas).
class BrutalLineChart extends StatelessWidget {
  final String title;
  final List<double> values;
  final Color color;
  final String unit;
  const BrutalLineChart({
    super.key,
    required this.title,
    required this.values,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 0.0 : values.reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
            ),
            if (values.isNotEmpty) Tag('máx ${maxV.toStringAsFixed(1)} $unit', color: color),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          clipBehavior: Clip.hardEdge,
          decoration: brutalDecoration(color: AppColors.paper, shadow: 0, radius: 4),
          child: values.length < 2
              ? const Center(
                  child: Text('ESPERANDO DATOS…',
                      style: TextStyle(
                          color: AppColors.inkSoft, fontWeight: FontWeight.w900, letterSpacing: 1)),
                )
              : CustomPaint(size: Size.infinite, painter: _ChartPainter(values, color)),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _ChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxV = math.max(values.reduce(math.max), 0.1);
    const pad = 8.0;
    final h = size.height - pad * 2;
    final dx = size.width / (values.length - 1);
    Offset pt(int i) => Offset(i * dx, pad + h - (values[i] / maxV) * h);

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.75));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values.length != values.length || old.color != color;
}
