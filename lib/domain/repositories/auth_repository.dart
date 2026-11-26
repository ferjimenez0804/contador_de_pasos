import '../entities/bio_method.dart';
import '../entities/body_data.dart';
import '../entities/user_account.dart';

/// Contrato de autenticación. La implementación vive en la capa de datos.
abstract class AuthRepository {
  UserAccount? get current;

  /// Devuelve null si todo salió bien, o el mensaje de error.
  Future<String?> register({
    required String name,
    required String username,
    required String password,
    required bool biometric,
    required BioMethod bioMethod,
    required BodyData body,
  });

  Future<UserAccount?> login(String username, String password);

  Future<void> startSession(UserAccount account);

  /// Último usuario que inició sesión, si tiene la biometría activada.
  Future<UserAccount?> lastBiometricUser();

  Future<void> setBiometric({required bool enabled, BioMethod? method});

  Future<void> updateProfile(BodyData body);

  void logout();
}
