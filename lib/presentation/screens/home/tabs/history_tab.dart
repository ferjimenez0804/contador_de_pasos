import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../domain/entities/workout.dart';
import '../../../widgets/brutal.dart';
import '../../workout/workout_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  final List<Workout> workouts;
  final VoidCallback onChanged;
  const HistoryTab({super.key, required this.workouts, required this.onChanged});

  static const _stripes = [AppColors.lime, AppColors.sun, AppColors.lilac, AppColors.mint];

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BrutalBox(
            color: AppColors.card,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: brutalDecoration(color: AppColors.sun, shadow: 0),
                  child: const Icon(Icons.directions_run_rounded, size: 44, color: AppColors.ink),
                ),
                const SizedBox(height: 14),
                const Text('SIN ENTRENAMIENTOS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Inicia uno desde la pestaña Hoy.',
                    style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: workouts.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ScreenTitle('Historial', underline: AppColors.sun),
                const Spacer(),
                Tag('${workouts.length} total', color: AppColors.card),
              ],
            ),
          );
        }
        final w = workouts[i - 1];
        final number = (workouts.length - (i - 1)).toString().padLeft(2, '0');
        return GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
            );
            onChanged();
          },
          child: Container(
            decoration: brutalDecoration(color: AppColors.card, shadow: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _stripes[(i - 1) % _stripes.length],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius - 2)),
                    border: const Border(bottom: BorderSide(color: AppColors.ink, width: kBorder)),
                  ),
                  child: Row(
                    children: [
                      Text('#$number',
                          style: const TextStyle(
                              fontFamily: AppTheme.mono, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(DateFormat('dd/MM/yyyy · HH:mm').format(w.date),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('Tiempo', fmtDuration(w.durationSec)),
                      _stat('Pasos', '${w.steps}'),
                      _stat('Km', fmtKm(w.distanceM)),
                      _stat('Kcal', w.calories.toStringAsFixed(0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.inkSoft)),
          Text(value,
              style: const TextStyle(fontFamily: AppTheme.mono, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      );
}
