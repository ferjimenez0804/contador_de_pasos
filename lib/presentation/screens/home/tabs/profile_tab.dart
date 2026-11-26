import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../data/services/biometric_service.dart';
import '../../../../domain/entities/bio_method.dart';
import '../../../../domain/entities/workout.dart';
import '../../../widgets/bio_method_picker.dart';
import '../../../widgets/bmi_gauge.dart';
import '../../../widgets/brutal.dart';
import '../../profile/edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  final List<Workout> workouts;
  final VoidCallback onLogout;
  final VoidCallback onProfileChanged;
  const ProfileTab({
    super.key,
    required this.workouts,
    required this.onLogout,
    required this.onProfileChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  BioCapabilities _caps = BioCapabilities.none;

  @override
  void initState() {
    super.initState();
    BiometricService.capabilities().then((c) {
      if (mounted) setState(() => _caps = c);
    });
  }

  /// Activa/desactiva o cambia de método. Activar o cambiar exige verificar.
  Future<void> _setBio({required bool enabled, required BioMethod method}) async {
    if (enabled) {
      final r = await BiometricService.authenticate(method, 'activar el acceso biométrico');
      if (!mounted) return;
      if (!r.ok) {
        showBrutalSnack(context, r.message, error: true);
        return;
      }
    }
    await Di.auth.setBiometric(enabled: enabled, method: method);
    if (!mounted) return;
    setState(() {});
    showBrutalSnack(
      context,
      enabled ? 'Acceso con ${method.label} activado.' : 'Acceso biométrico desactivado.',
    );
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    setState(() {});
    widget.onProfileChanged();
  }

  Widget _mini(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: AppTheme.mono, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = Di.auth.current!;
    final w = widget.workouts;
    final totalSteps = w.fold<int>(0, (a, e) => a + e.steps);
    final totalDist = w.fold<double>(0, (a, e) => a + e.distanceM);
    final totalSec = w.fold<int>(0, (a, e) => a + e.durationSec);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // ---- Credencial
        Container(
          decoration: brutalDecoration(color: AppColors.lilac, shadow: 6),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: brutalDecoration(color: AppColors.coral, shadow: 0),
                child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ATLETA',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                    Text(user.name.toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 4),
                    Tag('@${user.username}', color: AppColors.card),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SectionLabel('01', 'Mis datos'),
        if (user.hasBodyData)
          BrutalBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _mini('Peso', '${user.weightKg!.round()}kg'),
                    _mini('Altura', '${user.heightCm}cm'),
                    _mini('Edad', user.age == null ? '—' : '${user.age}'),
                    _mini('Sexo', user.sex == 'F' ? 'F' : (user.sex == 'M' ? 'M' : '—')),
                  ],
                ),
                const SizedBox(height: 16),
                BmiGauge(weightKg: user.weightKg!, heightCm: user.heightCm!),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Tag('Meta ${user.dailyGoal} pasos', color: AppColors.lime, icon: Icons.flag_rounded),
                    const Spacer(),
                    SquareIconButton(icon: Icons.edit_rounded, color: AppColors.sun, onTap: _edit),
                  ],
                ),
              ],
            ),
          )
        else
          BrutalBox(
            color: AppColors.sun,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COMPLETA TUS DATOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                    'Agrega peso, estatura, edad y sexo para ver tu IMC y calcular mejor tus calorías.'),
                const SizedBox(height: 12),
                BrutalButton(
                    label: 'Agregar datos', icon: Icons.add_rounded, color: AppColors.card, onPressed: _edit),
              ],
            ),
          ),

        const SectionLabel('02', 'Totales'),
        MetricGrid(
          children: [
            MetricBlock(icon: Icons.fitness_center_rounded, label: 'Sesiones', value: '${w.length}', color: AppColors.card),
            MetricBlock(icon: Icons.directions_walk_rounded, label: 'Pasos', value: '$totalSteps', color: AppColors.mint),
            MetricBlock(icon: Icons.route_rounded, label: 'Distancia', value: fmtKm(totalDist), unit: 'km', color: AppColors.sun),
            MetricBlock(icon: Icons.timer_rounded, label: 'Tiempo', value: fmtDuration(totalSec), color: AppColors.card),
          ],
        ),

        const SectionLabel('03', 'Biometría'),
        BrutalBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(bioIcon(user.bioMethod), size: 30, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACCESO BIOMÉTRICO',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text(
                          user.biometric
                              ? 'Activo con ${user.bioMethod.label}'
                              : 'Protege tu perfil al abrir la app',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  BrutalSwitch(
                    value: user.biometric,
                    onChanged: _caps.any
                        ? (v) => _setBio(enabled: v, method: user.bioMethod)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BioMethodPicker(
                caps: _caps,
                selected: user.bioMethod,
                onSelect: (m) {
                  if (m == user.bioMethod) return;
                  _setBio(enabled: user.biometric, method: m);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BrutalButton(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          color: AppColors.coral,
          onPressed: widget.onLogout,
        ),
      ],
    );
  }
}
