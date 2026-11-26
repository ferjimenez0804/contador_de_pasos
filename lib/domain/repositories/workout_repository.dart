import '../entities/workout.dart';

/// Contrato del historial de entrenamientos por usuario.
abstract class WorkoutRepository {
  Future<List<Workout>> load(String username);
  Future<void> add(String username, Workout workout);
  Future<void> delete(String username, int id);
}
