import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/entities/bio_method.dart';
import '../../domain/entities/body_data.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_storage.dart';

/// Registro, login (hash SHA-256) y sesión en memoria.
/// La sesión NO se persiste: la app siempre pide biometría/contraseña al abrir.
class AuthRepositoryImpl implements AuthRepository {
  final LocalStorage _storage;
  AuthRepositoryImpl(this._storage);

  static const _usersKey = 'users_v1';
  static const _lastUserKey = 'last_user';

  UserAccount? _current;

  @override
  UserAccount? get current => _current;

  String _hash(String username, String password) =>
      sha256.convert(utf8.encode('$username::$password::fitpulse')).toString();

  String _norm(String u) => u.trim().toLowerCase();

  UserAccount _fromData(String username, Map data) => UserAccount(
        username: username,
        name: data['name'] as String,
        biometric: (data['biometric'] ?? false) as bool,
        bioMethod: bioMethodFromKey(data['bioMethod'] as String?),
        weightKg: (data['weight'] as num?)?.toDouble(),
        heightCm: (data['height'] as num?)?.toInt(),
        age: (data['age'] as num?)?.toInt(),
        sex: data['sex'] as String?,
        dailyGoal: ((data['goal'] ?? 10000) as num).toInt(),
      );

  Future<Map<String, dynamic>> _readUsers() async {
    final raw = await _storage.read(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeUsers(Map<String, dynamic> users) =>
      _storage.write(_usersKey, jsonEncode(users));

  @override
  Future<String?> register({
    required String name,
    required String username,
    required String password,
    required bool biometric,
    required BioMethod bioMethod,
    required BodyData body,
  }) async {
    final u = _norm(username);
    final users = await _readUsers();
    if (users.containsKey(u)) return 'Ese usuario ya existe.';
    users[u] = {
      'name': name.trim(),
      'hash': _hash(u, password),
      'biometric': biometric,
      'bioMethod': bioMethod.key,
      'weight': body.weightKg,
      'height': body.heightCm,
      'age': body.age,
      'sex': body.sex,
      'goal': body.dailyGoal,
    };
    await _writeUsers(users);
    await startSession(_fromData(u, users[u] as Map));
    return null;
  }

  @override
  Future<UserAccount?> login(String username, String password) async {
    final u = _norm(username);
    final users = await _readUsers();
    final data = users[u];
    if (data == null) return null;
    if (data['hash'] != _hash(u, password)) return null;
    final acc = _fromData(u, data as Map);
    await startSession(acc);
    return acc;
  }

  @override
  Future<void> startSession(UserAccount account) async {
    _current = account;
    await _storage.write(_lastUserKey, account.username);
  }

  @override
  Future<UserAccount?> lastBiometricUser() async {
    final last = await _storage.read(_lastUserKey);
    if (last == null) return null;
    final data = (await _readUsers())[last];
    if (data == null || data['biometric'] != true) return null;
    return _fromData(last, data as Map);
  }

  @override
  Future<void> setBiometric({required bool enabled, BioMethod? method}) async {
    final acc = _current;
    if (acc == null) return;
    final users = await _readUsers();
    final data = users[acc.username];
    if (data == null) return;
    data['biometric'] = enabled;
    if (method != null) data['bioMethod'] = method.key;
    users[acc.username] = data;
    await _writeUsers(users);
    _current = acc.copyWith(biometric: enabled, bioMethod: method);
  }

  @override
  Future<void> updateProfile(BodyData body) async {
    final acc = _current;
    if (acc == null) return;
    final users = await _readUsers();
    final data = users[acc.username];
    if (data == null) return;
    data['weight'] = body.weightKg;
    data['height'] = body.heightCm;
    data['age'] = body.age;
    data['sex'] = body.sex;
    data['goal'] = body.dailyGoal;
    users[acc.username] = data;
    await _writeUsers(users);
    _current = acc.copyWith(
      weightKg: body.weightKg,
      heightCm: body.heightCm,
      age: body.age,
      sex: body.sex,
      dailyGoal: body.dailyGoal,
    );
  }

  @override
  void logout() => _current = null;
}
