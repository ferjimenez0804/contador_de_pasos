import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/workout.dart';

enum MotionState { rest, walking, jogging }

/// Orquesta TODOS los sensores de una sesión de entrenamiento:
/// podómetro, acelerómetro, giroscopio y GPS.
///
/// Optimización de batería: los streams solo existen mientras la sesión está
/// corriendo. [pause] y [dispose] cancelan todas las suscripciones.
///
/// Segundo plano: se liberan acelerómetro y giroscopio, pero la intensidad,
/// el tiempo por estado y las calorías se SIGUEN calculando a partir de la
/// cadencia del podómetro y la velocidad del GPS (antes se quedaban congelados).
class WorkoutController extends ChangeNotifier {
  // Se personalizan con los datos del usuario (estatura, peso, sexo).
  double stepLengthM = 0.75;
  double weightKg = 70;
  double _kcal = 0;
  static const double _gravity = 9.80665;

  // Umbrales de intensidad (aceleración dinámica suavizada, m/s²). Ajustables.
  static const double restThreshold = 0.8;
  static const double jogThreshold = 3.5;

  // Umbrales para estimar el movimiento en segundo plano.
  static const double _walkCadence = 30; // pasos/min
  static const double _jogCadence = 140; // pasos/min
  static const double _walkSpeed = 1.5; // km/h
  static const double _jogSpeed = 7.5; // km/h

  // ---- Estado de la sesión
  bool started = false;
  bool running = false;

  /// true cuando la app está en segundo plano y solo siguen GPS + podómetro.
  bool inBackground = false;
  bool autoPaused = false;
  DateTime? startedAt;

  // ---- Disponibilidad / permisos
  bool hasLocationPerm = false;
  bool hasActivityPerm = false;
  bool gpsServiceOn = true;
  bool gpsSignal = false;
  bool pedometerAvailable = true;
  bool accelAvailable = true;
  bool gyroAvailable = true;

  // ---- Acelerómetro
  double ax = 0, ay = 0, az = 0;
  double _emaDyn = 0;
  double pitchDeg = 0, rollDeg = 0;
  int restSec = 0, walkSec = 0, jogSec = 0;

  // ---- Giroscopio (rad/s)
  double gx = 0, gy = 0, gz = 0;

  // ---- Podómetro
  int _accSteps = 0;
  int _lastPed = 0;
  int? _segBase;
  int _fallbackSteps = 0;
  double _filtMag = _gravity;
  bool _above = false;
  DateTime _lastStepAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ---- Estimación en segundo plano (cadencia + velocidad)
  final List<(DateTime, int)> _stepWindow = [];
  MotionState _bgMotion = MotionState.rest;
  double cadenceSpm = 0;

  // ---- GPS
  final List<LatLng> route = [];
  LatLng? current;
  double gpsDistanceM = 0;
  double speedKmh = 0;
  double maxSpeedKmh = 0;
  DateTime _lastFixAt = DateTime.fromMillisecondsSinceEpoch(0);
  int get gpsPoints => route.length;

  // ---- Muestras para gráficas (cada 2 s)
  final List<double> speedSamples = [];
  final List<double> intensitySamples = [];
  int _tickCount = 0;
  double _r1(double v) => (v * 10).round() / 10;

  // ---- Infraestructura
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<StepCount>? _pedSub;
  StreamSubscription<Position>? _gpsSub;
  Timer? _ticker;
  final Stopwatch _watch = Stopwatch();
  int _lastSecond = 0;

  // ---------------------------------------------------------------- getters
  int get elapsedSec => _watch.elapsed.inSeconds;

  int get steps {
    if (pedometerAvailable) {
      final seg = _segBase == null ? 0 : math.max(0, _lastPed - _segBase!);
      return _accSteps + seg;
    }
    return _fallbackSteps;
  }

  double get stepsDistanceM => steps * stepLengthM;
  double get distanceM => gpsDistanceM > 0 ? gpsDistanceM : stepsDistanceM;
  double get calories => _kcal;

  /// ¿El estado se está estimando sin acelerómetro (segundo plano)?
  bool get estimatingInBackground => inBackground && _accSub == null;

  double get intensity => estimatingInBackground ? _intensityFor(_bgMotion) : _emaDyn;

  MotionState get motion {
    if (estimatingInBackground) return _bgMotion;
    if (_emaDyn < restThreshold) return MotionState.rest;
    if (_emaDyn < jogThreshold) return MotionState.walking;
    return MotionState.jogging;
  }

  /// Intensidad representativa de cada estado (para gráficas en segundo plano).
  double _intensityFor(MotionState m) => switch (m) {
        MotionState.rest => 0.3,
        MotionState.walking => 2.0,
        MotionState.jogging => 4.5,
      };

  // ---------------------------------------------------------------- control
  Future<void> start({
    required bool location,
    required bool activity,
    double? weightKg,
    int? heightCm,
    String? sex,
  }) async {
    if (started) return;
    if (weightKg != null) this.weightKg = weightKg;
    if (heightCm != null) {
      // Zancada estimada: ~41.5 % de la estatura (41.3 % en mujeres).
      stepLengthM = heightCm * (sex == 'F' ? 0.413 : 0.415) / 100;
    }
    hasLocationPerm = location;
    hasActivityPerm = activity;
    started = true;
    startedAt = DateTime.now();
    await resume();
  }

  Future<void> resume() async {
    if (running || !started) return;
    autoPaused = false;
    running = true;
    _watch.start();
    _startSensors();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), _onTick);
    notifyListeners();
  }

  /// ¿Hay un servicio de GPS activo que permita seguir midiendo en segundo plano?
  bool get canRunInBackground => running && _gpsSub != null;

  /// Segundo plano: se LIBERA el giroscopio y también el acelerómetro cuando
  /// hay podómetro (son los que más batería consumen y Android los limita).
  /// Si el equipo NO tiene podómetro, el acelerómetro se mantiene porque es
  /// el único que puede contar los pasos.
  void enterBackground() {
    if (!running || inBackground) return;
    inBackground = true;
    _gyroSub?.cancel();
    _gyroSub = null;
    if (pedometerAvailable) {
      _accSub?.cancel();
      _accSub = null;
    }
    _bgMotion = motionFromIntensity(_emaDyn);
    _stepWindow
      ..clear()
      ..add((DateTime.now(), steps));
  }

  /// Al volver a primer plano se reactivan los sensores de movimiento y la
  /// intensidad continúa desde el último valor estimado (sin saltos).
  void exitBackground() {
    if (!inBackground) return;
    if (estimatingInBackground) _emaDyn = _intensityFor(_bgMotion);
    inBackground = false;
    _stepWindow.clear();
    if (running) _subscribeMotion();
    notifyListeners();
  }

  static MotionState motionFromIntensity(double v) {
    if (v < restThreshold) return MotionState.rest;
    if (v < jogThreshold) return MotionState.walking;
    return MotionState.jogging;
  }

  void _subscribeMotion() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(_onAcc, onError: (Object _) => accelAvailable = false);
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(_onGyro, onError: (Object _) => gyroAvailable = false);
  }

  void pause({bool auto = false}) {
    if (!running) return;
    inBackground = false;
    _stepWindow.clear();
    _stopSensors();
    _ticker?.cancel();
    _ticker = null;
    _watch.stop();
    running = false;
    autoPaused = auto;
    speedKmh = 0;
    notifyListeners();
  }

  Workout buildWorkout() => Workout(
        id: DateTime.now().millisecondsSinceEpoch,
        date: startedAt ?? DateTime.now(),
        durationSec: elapsedSec,
        steps: steps,
        distanceM: distanceM,
        calories: calories,
        restSec: restSec,
        walkSec: walkSec,
        jogSec: jogSec,
        maxSpeedKmh: maxSpeedKmh,
        route: List.of(route),
        speedSamples: List.of(speedSamples),
        intensitySamples: List.of(intensitySamples),
      );

  // ---------------------------------------------------------------- sensores
  void _startSensors() {
    _segBase = null;

    _subscribeMotion();

    if (hasActivityPerm) {
      _pedSub = Pedometer.stepCountStream.listen(
        _onStep,
        onError: (Object _) => pedometerAvailable = false,
      );
    } else {
      // Sin permiso de actividad física: se usa el detector por acelerómetro.
      pedometerAvailable = false;
    }

    _startGps();
  }

  void _stopSensors() {
    _closeStepSegment();
    _accSub?.cancel();
    _gyroSub?.cancel();
    _pedSub?.cancel();
    _gpsSub?.cancel();
    _accSub = _gyroSub = null;
    _pedSub = null;
    _gpsSub = null;
    gpsSignal = false;
  }

  void _closeStepSegment() {
    if (_segBase != null) {
      _accSteps += math.max(0, _lastPed - _segBase!);
    }
    _segBase = null;
  }

  Future<void> _startGps() async {
    if (!hasLocationPerm) return;
    try {
      gpsServiceOn = await Geolocator.isLocationServiceEnabled();
      if (!gpsServiceOn || !running) return;

      // Posición inicial rápida: centra el mapa y marca el punto de partida.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && current == null) {
          current = LatLng(last.latitude, last.longitude);
        }
        final first = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        if (!running) return;
        _onPosition(first);
      } catch (_) {
        // Sin fix inicial (p. ej. estás en interiores): el stream seguirá intentando.
      }

      if (!running || _gpsSub != null) return;
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 2),
          // Servicio en primer plano: mantiene el GPS vivo con la pantalla apagada
          // o con la app en segundo plano (muestra una notificación fija).
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'FitPulse',
            notificationText: 'Registrando tu entrenamiento…',
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      ).listen(_onPosition, onError: (Object _) => gpsSignal = false);
    } catch (_) {
      gpsSignal = false;
    }
  }

  // ---------------------------------------------------------------- handlers
  void _onAcc(AccelerometerEvent e) {
    ax = e.x;
    ay = e.y;
    az = e.z;
    final mag = math.sqrt(ax * ax + ay * ay + az * az);

    // Intensidad: desviación de la gravedad, suavizada (media móvil exponencial).
    _emaDyn = 0.92 * _emaDyn + 0.08 * (mag - _gravity).abs();

    // Inclinación (orientación) a partir de la gravedad.
    final pitch = math.atan2(-ax, math.sqrt(ay * ay + az * az)) * 180 / math.pi;
    final roll = math.atan2(ay, az) * 180 / math.pi;
    pitchDeg = 0.8 * pitchDeg + 0.2 * pitch;
    rollDeg = 0.8 * rollDeg + 0.2 * roll;

    // Fallback de pasos por detección de picos (dispositivos sin STEP_COUNTER).
    _filtMag = 0.8 * _filtMag + 0.2 * mag;
    final now = DateTime.now();
    if (!_above &&
        _filtMag > _gravity + 1.1 &&
        now.difference(_lastStepAt).inMilliseconds > 300) {
      _above = true;
      _lastStepAt = now;
      _fallbackSteps++;
    } else if (_above && _filtMag < _gravity + 0.4) {
      _above = false;
    }
  }

  void _onGyro(GyroscopeEvent e) {
    gx = e.x;
    gy = e.y;
    gz = e.z;
  }

  void _onStep(StepCount e) {
    _lastPed = e.steps;
    _segBase ??= e.steps;
  }

  void _onPosition(Position p) {
    gpsSignal = p.accuracy <= 50;
    _lastFixAt = DateTime.now();
    final point = LatLng(p.latitude, p.longitude);
    current = point;
    if (p.accuracy > 50) return; // descarta lecturas muy imprecisas

    if (route.isNotEmpty) {
      final d = Geolocator.distanceBetween(
        route.last.latitude,
        route.last.longitude,
        point.latitude,
        point.longitude,
      );
      if (d < 2) return; // ruido
      gpsDistanceM += d;
    }
    route.add(point);
    speedKmh = math.max(0, p.speed * 3.6);
    if (speedKmh > maxSpeedKmh) maxSpeedKmh = speedKmh;
  }

  /// En segundo plano: estado de movimiento a partir de la cadencia
  /// (pasos/min en una ventana de 15 s) y de la velocidad del GPS.
  void _updateBackgroundMotion() {
    final now = DateTime.now();
    _stepWindow.add((now, steps));
    _stepWindow.removeWhere((e) => now.difference(e.$1).inSeconds > 15);

    cadenceSpm = 0;
    final first = _stepWindow.first;
    final secs = now.difference(first.$1).inMilliseconds / 1000;
    if (secs >= 3) cadenceSpm = math.max(0, steps - first.$2) / secs * 60;

    final v = speedKmh;
    if (cadenceSpm >= _jogCadence || v >= _jogSpeed) {
      _bgMotion = MotionState.jogging;
    } else if (cadenceSpm >= _walkCadence || v >= _walkSpeed) {
      _bgMotion = MotionState.walking;
    } else {
      _bgMotion = MotionState.rest;
    }
  }

  void _onTick(Timer _) {
    // Si no hay fixes recientes (estás quieto), la velocidad es 0.
    if (DateTime.now().difference(_lastFixAt).inSeconds > 6) speedKmh = 0;
    if (estimatingInBackground) _updateBackgroundMotion();

    final sec = elapsedSec;
    while (_lastSecond < sec) {
      _lastSecond++;
      final m = motion;
      switch (m) {
        case MotionState.rest:
          restSec++;
        case MotionState.walking:
          walkSec++;
        case MotionState.jogging:
          jogSec++;
      }
      // Calorías por tiempo: MET según la intensidad x peso del usuario.
      final met = switch (m) {
        MotionState.rest => 1.3,
        MotionState.walking => 3.5,
        MotionState.jogging => 8.0,
      };
      _kcal += met * weightKg / 3600;
    }
    if (++_tickCount % 8 == 0) {
      speedSamples.add(_r1(speedKmh));
      intensitySamples.add(_r1(intensity));
    }
    // En segundo plano no se repinta la UI (ahorra batería).
    if (!inBackground) notifyListeners(); // máx. 4 repintados/seg
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopSensors();
    super.dispose();
  }
}
