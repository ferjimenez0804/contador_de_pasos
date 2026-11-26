import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/brutal.dart';

class PermissionResult {
  final bool location;
  final bool activity;
  const PermissionResult({required this.location, required this.activity});
}

/// Permisos en tiempo de ejecución con diálogos informativos previos.
class PermissionFlow {
  /// Android 13+: la notificación del servicio en primer plano necesita permiso.
  /// No es obligatorio: si se niega, el entrenamiento funciona igual.
  static Future<void> _askNotification() async {
    final s = await Permission.notification.status;
    if (s.isDenied) await Permission.notification.request();
  }

  static Future<PermissionResult> ensureWorkoutPermissions(BuildContext context) async {
    var loc = await Permission.locationWhenInUse.status;
    var act = await Permission.activityRecognition.status;
    if (loc.isGranted && act.isGranted) {
      await _askNotification();
      return const PermissionResult(location: true, activity: true);
    }
    if (!context.mounted) {
      return PermissionResult(location: loc.isGranted, activity: act.isGranted);
    }

    final accepted = await showBrutalDialog<bool>(
      context: context,
      dismissible: false,
      icon: Icons.sensors_rounded,
      iconColor: AppColors.sun,
      title: 'Permisos necesarios',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para registrar tu entrenamiento necesitamos:'),
          SizedBox(height: 12),
          _PermRow(Icons.location_on_rounded, 'Ubicación',
              'Trazar tu recorrido y calcular distancia y velocidad.'),
          SizedBox(height: 10),
          _PermRow(Icons.directions_walk_rounded, 'Actividad física',
              'Contar tus pasos con el podómetro del dispositivo.'),
          SizedBox(height: 10),
          _PermRow(Icons.notifications_active_rounded, 'Notificaciones',
              'Avisarte mientras el entrenamiento sigue en segundo plano.'),
        ],
      ),
      actions: (ctx) => [
        BrutalButton(
            label: 'Ahora no',
            compact: true,
            color: AppColors.card,
            onPressed: () => Navigator.pop(ctx, false)),
        BrutalButton(label: 'Continuar', compact: true, onPressed: () => Navigator.pop(ctx, true)),
      ],
    );

    if (accepted != true) {
      return PermissionResult(location: loc.isGranted, activity: act.isGranted);
    }

    final res = await [Permission.locationWhenInUse, Permission.activityRecognition].request();
    loc = res[Permission.locationWhenInUse] ?? loc;
    act = res[Permission.activityRecognition] ?? act;
    await _askNotification();

    if ((loc.isPermanentlyDenied || act.isPermanentlyDenied) && context.mounted) {
      final open = await showBrutalDialog<bool>(
        context: context,
        icon: Icons.block_rounded,
        iconColor: AppColors.coral,
        title: 'Permiso bloqueado',
        content: const Text(
          'Denegaste un permiso de forma permanente. Actívalo desde los ajustes '
          'de la app para usar todos los sensores.',
        ),
        actions: (ctx) => [
          BrutalButton(
              label: 'Cancelar',
              compact: true,
              color: AppColors.card,
              onPressed: () => Navigator.pop(ctx, false)),
          BrutalButton(
              label: 'Ajustes', compact: true, onPressed: () => Navigator.pop(ctx, true)),
        ],
      );
      if (open == true) await openAppSettings();
    }

    return PermissionResult(location: loc.isGranted, activity: act.isGranted);
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _PermRow(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: brutalDecoration(color: AppColors.lime, shadow: 0, radius: 4),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              Text(text, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
