import 'dart:convert';

import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/local_storage.dart';

/// Persistencia local del historial (fecha, duración, pasos, ruta...) por usuario.
class WorkoutRepositoryImpl implements WorkoutRepository {
  final LocalStorage _storage;
  WorkoutRepositoryImpl(this._storage);

  String _key(String user) => 'workouts_$user';

  @override
  Future<List<Workout>> load(String username) async {
    final raw = await _storage.read(_key(username));
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Workout.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String user, List<Workout> list) => _storage.write(
      _key(user), jsonEncode(list.map((w) => w.toJson()).toList()));

  @override
  Future<void> add(String username, Workout workout) async {
    final list = await load(username);
    list.add(workout);
    await _save(username, list);
  }

  @override
  Future<void> delete(String username, int id) async {
    final list = await load(username);
    list.removeWhere((w) => w.id == id);
    await _save(username, list);
  }
}
