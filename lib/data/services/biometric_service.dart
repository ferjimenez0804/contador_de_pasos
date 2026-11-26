import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/entities/bio_method.dart';

enum BioStatus { success, failed, unavailable, error }

class BioResult {
  final BioStatus status;
  final String message;
  const BioResult(this.status, this.message);
  bool get ok => status == BioStatus.success;
}

/// Qué métodos biométricos ofrece el dispositivo.
class BioCapabilities {
  final bool fingerprint;
  final bool face;
  const BioCapabilities({required this.fingerprint, required this.face});

  static const none = BioCapabilities(fingerprint: false, face: false);

  bool get any => fingerprint || face;

  bool supports(BioMethod m) => m == BioMethod.face ? face : fingerprint;

  List<BioMethod> get methods => [
        if (fingerprint) BioMethod.fingerprint,
        if (face) BioMethod.face,
      ];
}

/// Huella dactilar y reconocimiento facial con local_auth.
///
/// En Android el sistema no deja elegir el sensor: muestra el diálogo
/// biométrico con lo que el usuario tenga registrado (rostro y/o huella).
/// Android reporta las clases "strong" (huella o rostro 3D) y "weak"
/// (rostro por cámara en la mayoría de los equipos); local_auth acepta ambas.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<BioCapabilities> capabilities() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return BioCapabilities.none;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return BioCapabilities.none;
      final finger = types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong);
      final face = types.contains(BiometricType.face) ||
          types.contains(BiometricType.weak);
      return BioCapabilities(fingerprint: finger, face: face);
    } catch (_) {
      return BioCapabilities.none;
    }
  }

  static String _reason(BioMethod m, String action) => m == BioMethod.face
      ? 'Mira a la cámara para $action'
      : 'Coloca tu dedo en el sensor para $action';

  static Future<BioResult> authenticate(BioMethod method, String action) async {
    final caps = await capabilities();
    if (!caps.supports(method)) {
      return BioResult(
        BioStatus.unavailable,
        method == BioMethod.face
            ? 'Este dispositivo no tiene un rostro registrado o no es compatible.'
            : 'Este dispositivo no tiene una huella registrada o no es compatible.',
      );
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: _reason(method, action),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) {
        return BioResult(
          BioStatus.success,
          method == BioMethod.face
              ? 'Rostro verificado correctamente.'
              : 'Huella verificada correctamente.',
        );
      }
      return BioResult(
        BioStatus.failed,
        method == BioMethod.face
            ? 'Rostro no reconocido. Intenta de nuevo.'
            : 'Huella no reconocida. Intenta de nuevo.',
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('lock')) {
        return const BioResult(
          BioStatus.error,
          'Demasiados intentos. Espera unos segundos o usa tu contraseña.',
        );
      }
      if (code.contains('notenrolled')) {
        return BioResult(
          BioStatus.unavailable,
          'No hay ${method.label} registrado en los ajustes del teléfono.',
        );
      }
      return BioResult(BioStatus.error, e.message ?? 'Error de autenticación biométrica.');
    } catch (_) {
      return const BioResult(BioStatus.error, 'Error de autenticación biométrica.');
    }
  }
}
