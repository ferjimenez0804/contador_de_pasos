import '../../data/datasources/local_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/workout_repository.dart';

/// Inyección de dependencias sencilla: la capa de presentación solo conoce
/// las interfaces del dominio, nunca las implementaciones de datos.
class Di {
  Di._();

  static final LocalStorage _storage = LocalStorage();

  static final AuthRepository auth = AuthRepositoryImpl(_storage);
  static final WorkoutRepository workouts = WorkoutRepositoryImpl(_storage);
}
