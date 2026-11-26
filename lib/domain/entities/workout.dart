import 'package:latlong2/latlong.dart';

class Workout {
  final int id;
  final DateTime date;
  final int durationSec;
  final int steps;
  final double distanceM;
  final double calories;
  final int restSec;
  final int walkSec;
  final int jogSec;
  final double maxSpeedKmh;
  final List<LatLng> route;

  /// Muestras cada 2 s para las gráficas de actividad.
  final List<double> speedSamples;
  final List<double> intensitySamples;

  const Workout({
    required this.id,
    required this.date,
    required this.durationSec,
    required this.steps,
    required this.distanceM,
    required this.calories,
    required this.restSec,
    required this.walkSec,
    required this.jogSec,
    required this.maxSpeedKmh,
    required this.route,
    this.speedSamples = const [],
    this.intensitySamples = const [],
  });

  double get avgSpeedKmh =>
      durationSec == 0 ? 0 : (distanceM / 1000) / (durationSec / 3600);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'durationSec': durationSec,
        'steps': steps,
        'distanceM': distanceM,
        'calories': calories,
        'restSec': restSec,
        'walkSec': walkSec,
        'jogSec': jogSec,
        'maxSpeedKmh': maxSpeedKmh,
        'route': route.map((p) => [p.latitude, p.longitude]).toList(),
        'speedSamples': speedSamples,
        'intensitySamples': intensitySamples,
      };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        id: j['id'] as int,
        date: DateTime.parse(j['date'] as String),
        durationSec: j['durationSec'] as int,
        steps: j['steps'] as int,
        distanceM: (j['distanceM'] as num).toDouble(),
        calories: (j['calories'] as num).toDouble(),
        restSec: (j['restSec'] ?? 0) as int,
        walkSec: (j['walkSec'] ?? 0) as int,
        jogSec: (j['jogSec'] ?? 0) as int,
        maxSpeedKmh: ((j['maxSpeedKmh'] ?? 0) as num).toDouble(),
        route: ((j['route'] ?? []) as List)
            .map((e) => LatLng((e[0] as num).toDouble(), (e[1] as num).toDouble()))
            .toList(),
        speedSamples: ((j['speedSamples'] ?? []) as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        intensitySamples: ((j['intensitySamples'] ?? []) as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}
