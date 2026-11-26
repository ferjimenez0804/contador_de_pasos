import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../controllers/workout_controller.dart';
import '../../helpers/permission_flow.dart';
import '../../widgets/brutal.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/route_map.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  final WorkoutController c = WorkoutController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Segundo plano: si hay GPS activo (servicio en primer plano) el entrenamiento
  /// SIGUE registrándose; se liberan los sensores de movimiento y el estado se
  /// estima con podómetro + GPS. Sin servicio de GPS, se pausa y se reanuda al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (c.canRunInBackground) {
        c.enterBackground();
      } else {
        c.pause(auto: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (c.inBackground) {
        c.exitBackground();
        if (mounted) showBrutalSnack(context, 'Seguiste registrando en segundo plano.');
      } else if (c.autoPaused) {
        c.resume();
        if (mounted) showBrutalSnack(context, 'Entrenamiento reanudado.');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.dispose(); // cancela todos los streams de sensores y GPS
    super.dispose();
  }

  Future<void> _start() async {
    final perms = await PermissionFlow.ensureWorkoutPermissions(context);
    if (!mounted) return;
    if (!perms.location) {
      showBrutalSnack(context, 'Sin permiso de ubicación: no se trazará la ruta.', error: true);
    }
    if (!perms.activity) {
      showBrutalSnack(context, 'Sin permiso de actividad: los pasos se estimarán con el acelerómetro.',
          error: true);
    }
    final u = Di.auth.current;
    await c.start(
      location: perms.location,
      activity: perms.activity,
      weightKg: u?.weightKg,
      heightCm: u?.heightCm,
      sex: u?.sex,
    );
    if (mounted && c.hasLocationPerm && !c.gpsServiceOn) {
      showBrutalSnack(context, 'El GPS del dispositivo está apagado.', error: true);
    }
  }

  Future<void> _finish() async {
    c.pause();
    if (c.elapsedSec < 3) {
      showBrutalSnack(context, 'Sesión demasiado corta para guardarse.', error: true);
      return;
    }
    final w = c.buildWorkout();
    final user = Di.auth.current;
    if (user != null) await Di.workouts.add(user.username, w);
    if (!mounted) return;
    await showBrutalDialog<void>(
      context: context,
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.sun,
      title: '¡Entrenamiento guardado!',
      content: Text(
        'Duración   ${fmtDuration(w.durationSec)}\n'
        'Pasos      ${w.steps}\n'
        'Distancia  ${fmtKm(w.distanceM)} km\n'
        'Calorías   ${w.calories.toStringAsFixed(0)} kcal',
        style: const TextStyle(fontFamily: AppTheme.mono, fontWeight: FontWeight.w800),
      ),
      actions: (ctx) => [
        BrutalButton(label: 'Listo', compact: true, onPressed: () => Navigator.pop(ctx)),
      ],
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmExit() async {
    final discard = await showBrutalDialog<bool>(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.coral,
      title: '¿Salir sin guardar?',
      content: const Text('Se perderá el entrenamiento en curso.'),
      actions: (ctx) => [
        BrutalButton(
            label: 'Seguir', compact: true, color: AppColors.card, onPressed: () => Navigator.pop(ctx, false)),
        BrutalButton(
            label: 'Descartar',
            compact: true,
            color: AppColors.coral,
            onPressed: () => Navigator.pop(ctx, true)),
      ],
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Color get _motionColor => switch (c.motion) {
        MotionState.rest => AppColors.cobalt,
        MotionState.walking => AppColors.lime,
        MotionState.jogging => AppColors.coral,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return PopScope(
          canPop: !c.started,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmExit();
          },
          child: BrutalScaffold(
            bottom: _controls(),
            child: Column(
              children: [
                BrutalTopBar(
                  title: 'Entrenamiento',
                  onBack: () => c.started ? _confirmExit() : Navigator.pop(context),
                  actions: [
                    Tag(
                      !c.started ? 'Listo' : (c.running ? 'En vivo' : 'Pausa'),
                      color: !c.started
                          ? AppColors.card
                          : (c.running ? AppColors.coral : AppColors.sun),
                      icon: c.running ? Icons.fiber_manual_record_rounded : null,
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    children: [
                      // ---- Cronómetro tipo marcador
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: brutalDecoration(color: AppColors.ink, shadow: 0),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.lime),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  fmtDuration(c.elapsedSec),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.mono,
                                    color: AppColors.lime,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ---- Mapa
                      Container(
                        height: 230,
                        clipBehavior: Clip.hardEdge,
                        decoration: brutalDecoration(color: AppColors.card, shadow: 5),
                        child: Stack(
                          children: [
                            Positioned.fill(child: LiveMap(route: c.route, current: c.current)),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Tag(
                                !c.started
                                    ? 'GPS'
                                    : (!c.gpsServiceOn
                                        ? 'GPS apagado'
                                        : (c.gpsSignal ? 'GPS · ${c.gpsPoints} pts' : 'Buscando…')),
                                color: c.gpsSignal ? AppColors.lime : AppColors.card,
                                icon: c.gpsSignal ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _motionCard(),
                      const SizedBox(height: 16),
                      MetricGrid(
                        children: [
                          MetricBlock(icon: Icons.directions_walk_rounded, label: 'Pasos', value: '${c.steps}', color: AppColors.lime),
                          MetricBlock(icon: Icons.route_rounded, label: 'Distancia', value: fmtKm(c.distanceM), unit: 'km', color: AppColors.sun),
                          MetricBlock(icon: Icons.speed_rounded, label: 'Velocidad', value: c.speedKmh.toStringAsFixed(1), unit: 'km/h', color: AppColors.mint),
                          MetricBlock(icon: Icons.local_fire_department_rounded, label: 'Calorías', value: c.calories.toStringAsFixed(0), unit: 'kcal', color: AppColors.coral),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                        child: Text(
                          'Distancia estimada por pasos: ${fmtKm(c.stepsDistanceM)} km'
                          '${c.pedometerAvailable ? '' : '  ·  pasos por acelerómetro'}',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      BrutalBox(
                        child: BrutalLineChart(
                          title: 'Velocidad',
                          values: c.speedSamples,
                          color: AppColors.cobalt,
                          unit: 'km/h',
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalBox(
                        child: BrutalLineChart(
                          title: 'Intensidad de movimiento',
                          values: c.intensitySamples,
                          color: AppColors.lime,
                          unit: 'm/s²',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _accelCard(),
                      const SizedBox(height: 16),
                      _gyroCard(),
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

  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: !c.started
            ? BrutalButton(
                label: 'Iniciar entrenamiento',
                icon: Icons.play_arrow_rounded,
                color: AppColors.coral,
                onPressed: _start,
              )
            : Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      label: c.running ? 'Pausar' : 'Reanudar',
                      icon: c.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.card,
                      onPressed: c.running ? () => c.pause() : () => c.resume(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrutalButton(
                      label: 'Finalizar',
                      icon: Icons.stop_rounded,
                      color: AppColors.lime,
                      onPressed: _finish,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _motionCard() {
    final (label, icon) = switch (c.motion) {
      MotionState.rest => ('Descanso', Icons.self_improvement_rounded),
      MotionState.walking => ('Caminata', Icons.directions_walk_rounded),
      MotionState.jogging => ('Trote / Carrera', Icons.directions_run_rounded),
    };
    final color = c.running ? _motionColor : AppColors.card;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalDecoration(color: color, shadow: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: brutalDecoration(color: AppColors.card, shadow: 0),
                child: Icon(icon, color: AppColors.ink, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INTENSIDAD',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                    Text(
                      (c.running ? label : (c.started ? 'En pausa' : 'Sin iniciar')).toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color == AppColors.cobalt ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text('${c.intensity.toStringAsFixed(1)}\nm/s²',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w900,
                    color: color == AppColors.cobalt ? Colors.white : AppColors.ink,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          BrutalProgress(value: c.intensity / 6, color: AppColors.ink, height: 14),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag('Descanso ${fmtDuration(c.restSec)}', color: AppColors.card),
              Tag('Caminata ${fmtDuration(c.walkSec)}', color: AppColors.card),
              Tag('Trote ${fmtDuration(c.jogSec)}', color: AppColors.card),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accelCard() => BrutalBox(
        child: c.accelAvailable
            ? _axes('Acelerómetro · m/s²', Icons.vibration_rounded, c.ax, c.ay, c.az)
            : const Text('ACELERÓMETRO NO DISPONIBLE EN ESTE DISPOSITIVO.',
                style: TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _gyroCard() => BrutalBox(
        child: Row(
          children: [
            Expanded(
              child: c.gyroAvailable
                  ? _axes('Giroscopio · rad/s', Icons.screen_rotation_alt_rounded, c.gx, c.gy, c.gz)
                  : const Text('GIROSCOPIO NO DISPONIBLE EN ESTE DISPOSITIVO.',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: brutalDecoration(color: AppColors.paper, shadow: 0, radius: 33),
                  child: Transform.rotate(
                    angle: -c.rollDeg * math.pi / 180,
                    child: Center(
                      child: Container(width: 44, height: 6, color: AppColors.coral),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('P ${c.pitchDeg.toStringAsFixed(0)}° R ${c.rollDeg.toStringAsFixed(0)}°',
                    style: const TextStyle(fontFamily: AppTheme.mono, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      );

  Widget _axes(String title, IconData icon, double x, double y, double z) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 6),
              Flexible(
                child: Text(title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _axis('X', x, AppColors.coral)),
              const SizedBox(width: 8),
              Expanded(child: _axis('Y', y, AppColors.lime)),
              const SizedBox(width: 8),
              Expanded(child: _axis('Z', z, AppColors.cobalt)),
            ],
          ),
        ],
      );

  Widget _axis(String l, double v, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: brutalDecoration(color: AppColors.paper, shadow: 0, radius: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: color,
              child: Text(l,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color == AppColors.cobalt ? Colors.white : AppColors.ink)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(v.toStringAsFixed(2),
                  style: const TextStyle(
                      fontFamily: AppTheme.mono,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ),
          ],
        ),
      );
}
