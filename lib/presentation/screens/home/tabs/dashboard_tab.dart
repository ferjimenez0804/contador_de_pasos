import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../domain/entities/user_account.dart';
import '../../../../domain/entities/workout.dart';
import '../../../widgets/brutal.dart';

class DashboardTab extends StatelessWidget {
  final UserAccount user;
  final List<Workout> workouts;
  final VoidCallback onStart;

  const DashboardTab({
    super.key,
    required this.user,
    required this.workouts,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final goal = user.dailyGoal;
    final today = workouts.where((w) => sameDay(w.date, now)).toList();
    final steps = today.fold<int>(0, (a, w) => a + w.steps);
    final dist = today.fold<double>(0, (a, w) => a + w.distanceM);
    final kcal = today.fold<double>(0, (a, w) => a + w.calories);
    final secs = today.fold<int>(0, (a, w) => a + w.durationSec);
    final pct = goal == 0 ? 0.0 : steps / goal;

    final week = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final total =
          workouts.where((w) => sameDay(w.date, day)).fold<int>(0, (a, w) => a + w.steps);
      return (day: day, steps: total);
    });
    final maxSteps = week.fold<int>(1, (a, e) => e.steps > a ? e.steps : a);
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Tag(DateFormat('dd · MM · yyyy').format(now), color: AppColors.card),
            const Spacer(),
            Tag('${today.length} sesiones hoy', color: AppColors.lilac),
          ],
        ),
        const SizedBox(height: 14),
        ScreenTitle('Hola,\n${user.firstName}', underline: AppColors.coral),
        const SizedBox(height: 20),

        // ---- Bloque héroe: pasos del día
        Container(
          padding: const EdgeInsets.all(18),
          decoration: brutalDecoration(color: AppColors.lime, shadow: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PASOS DE HOY',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  NumberFormat.decimalPattern().format(steps),
                  style: const TextStyle(
                      fontFamily: AppTheme.mono,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -2),
                ),
              ),
              const SizedBox(height: 8),
              BrutalProgress(value: pct, color: AppColors.ink),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${(pct * 100).clamp(0, 999).toStringAsFixed(0)}%',
                      style: const TextStyle(fontFamily: AppTheme.mono, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('META ${NumberFormat.decimalPattern().format(goal)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 96,
                height: 168,
                clipBehavior: Clip.hardEdge,
                decoration: brutalDecoration(color: AppColors.card, shadow: 0),
                child: Image.asset(
                  'assets/images/hero_dashboard.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _mini(Icons.route_rounded, fmtKm(dist), 'km', AppColors.card)),
            const SizedBox(width: 10),
            Expanded(
                child: _mini(Icons.local_fire_department_rounded, kcal.toStringAsFixed(0), 'kcal',
                    AppColors.card)),
            const SizedBox(width: 10),
            Expanded(child: _mini(Icons.timer_outlined, fmtDuration(secs), '', AppColors.card)),
          ],
        ),
        const SizedBox(height: 18),
        BrutalButton(
          label: 'Iniciar entrenamiento',
          icon: Icons.play_arrow_rounded,
          color: AppColors.coral,
          onPressed: onStart,
        ),

        const SectionLabel('07', 'Últimos 7 días'),
        BrutalBox(
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: week.map((e) {
                final h = 110 * (e.steps / maxSteps);
                final isToday = sameDay(e.day, now);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(e.steps == 0 ? '·' : '${e.steps}',
                              style: const TextStyle(
                                  fontFamily: AppTheme.mono,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: e.steps == 0 ? 6 : h.clamp(10, 110).toDouble(),
                          decoration: brutalDecoration(
                            color: isToday ? AppColors.coral : AppColors.cobalt,
                            shadow: 0,
                            radius: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 22,
                          alignment: Alignment.center,
                          color: isToday ? AppColors.ink : Colors.transparent,
                          child: Text(labels[e.day.weekday - 1],
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isToday ? AppColors.paper : AppColors.ink,
                              )),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (workouts.isNotEmpty) ...[
          const SizedBox(height: 18),
          BrutalBox(
            color: AppColors.sun,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: brutalDecoration(color: AppColors.card, shadow: 0),
                  child: const Icon(Icons.sports_score_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ÚLTIMO ENTRENAMIENTO',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                      Text(
                        '${DateFormat('dd/MM HH:mm').format(workouts.first.date)} · '
                        '${fmtKm(workouts.first.distanceM)} km · ${workouts.first.steps} pasos',
                        style: const TextStyle(fontFamily: AppTheme.mono, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mini(IconData icon, String value, String unit, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: brutalDecoration(color: color, shadow: 3),
        child: Column(
          children: [
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      fontFamily: AppTheme.mono, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            if (unit.isNotEmpty)
              Text(unit.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      );
}
