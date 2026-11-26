import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/workout.dart';
import '../../widgets/brutal.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/route_map.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  Future<void> _delete(BuildContext context) async {
    final ok = await showBrutalDialog<bool>(
      context: context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.coral,
      title: 'Eliminar entrenamiento',
      content: const Text('Esta acción no se puede deshacer.'),
      actions: (ctx) => [
        BrutalButton(
            label: 'Cancelar',
            compact: true,
            color: AppColors.card,
            onPressed: () => Navigator.pop(ctx, false)),
        BrutalButton(
            label: 'Eliminar',
            compact: true,
            color: AppColors.coral,
            onPressed: () => Navigator.pop(ctx, true)),
      ],
    );
    if (ok != true) return;
    final user = Di.auth.current;
    if (user != null) await Di.workouts.delete(user.username, workout.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final total = (w.restSec + w.walkSec + w.jogSec).clamp(1, 1 << 30);
    return BrutalScaffold(
      child: Column(
        children: [
          BrutalTopBar(
            title: DateFormat('dd/MM/yyyy · HH:mm').format(w.date),
            actions: [
              SquareIconButton(
                icon: Icons.delete_outline_rounded,
                color: AppColors.coral,
                onTap: () => _delete(context),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Container(
                  height: 260,
                  clipBehavior: Clip.hardEdge,
                  decoration: brutalDecoration(color: AppColors.card, shadow: 5),
                  child: w.route.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'SIN RUTA GPS\nCamina al aire libre para trazarla.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                      : StaticRouteMap(route: w.route),
                ),
                const SizedBox(height: 18),
                MetricGrid(
                  children: [
                    MetricBlock(icon: Icons.timer_rounded, label: 'Duración', value: fmtDuration(w.durationSec), color: AppColors.card),
                    MetricBlock(icon: Icons.directions_walk_rounded, label: 'Pasos', value: '${w.steps}', color: AppColors.lime),
                    MetricBlock(icon: Icons.route_rounded, label: 'Distancia', value: fmtKm(w.distanceM), unit: 'km', color: AppColors.sun),
                    MetricBlock(icon: Icons.local_fire_department_rounded, label: 'Calorías', value: w.calories.toStringAsFixed(0), unit: 'kcal', color: AppColors.coral),
                    MetricBlock(icon: Icons.speed_rounded, label: 'Vel. prom.', value: w.avgSpeedKmh.toStringAsFixed(1), unit: 'km/h', color: AppColors.mint),
                    MetricBlock(icon: Icons.bolt_rounded, label: 'Vel. máx.', value: w.maxSpeedKmh.toStringAsFixed(1), unit: 'km/h', color: AppColors.lilac),
                  ],
                ),
                const SizedBox(height: 18),
                BrutalBox(
                  child: BrutalLineChart(
                    title: 'Velocidad',
                    values: w.speedSamples,
                    color: AppColors.cobalt,
                    unit: 'km/h',
                  ),
                ),
                const SizedBox(height: 16),
                BrutalBox(
                  child: BrutalLineChart(
                    title: 'Intensidad de movimiento',
                    values: w.intensitySamples,
                    color: AppColors.lime,
                    unit: 'm/s²',
                  ),
                ),
                const SizedBox(height: 16),
                BrutalBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIEMPO POR INTENSIDAD',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(
                        height: 26,
                        clipBehavior: Clip.hardEdge,
                        decoration: brutalDecoration(color: AppColors.card, shadow: 0, radius: 4),
                        child: Row(
                          children: [
                            if (w.restSec > 0)
                              Expanded(flex: math.max(1, w.restSec * 1000 ~/ total), child: Container(color: AppColors.cobalt)),
                            if (w.walkSec > 0)
                              Expanded(flex: math.max(1, w.walkSec * 1000 ~/ total), child: Container(color: AppColors.lime)),
                            if (w.jogSec > 0)
                              Expanded(flex: math.max(1, w.jogSec * 1000 ~/ total), child: Container(color: AppColors.coral)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _legend(AppColors.cobalt, 'Descanso', w.restSec),
                      _legend(AppColors.lime, 'Caminata', w.walkSec),
                      _legend(AppColors.coral, 'Trote / carrera', w.jogSec),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label, int secs) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: brutalDecoration(color: c, shadow: 0, radius: 2),
            ),
            const SizedBox(width: 8),
            Text(label.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
            const Spacer(),
            Text(fmtDuration(secs),
                style: const TextStyle(fontFamily: AppTheme.mono, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
