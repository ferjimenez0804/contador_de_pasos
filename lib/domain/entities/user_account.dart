import 'bio_method.dart';

class UserAccount {
  final String username;
  final String name;
  final bool biometric;
  final BioMethod bioMethod;
  final double? weightKg;
  final int? heightCm;
  final int? age;
  final String? sex; // 'M' o 'F'
  final int dailyGoal;

  const UserAccount({
    required this.username,
    required this.name,
    required this.biometric,
    this.bioMethod = BioMethod.fingerprint,
    this.weightKg,
    this.heightCm,
    this.age,
    this.sex,
    this.dailyGoal = 10000,
  });

  bool get hasBodyData => weightKg != null && heightCm != null;

  String get sexLabel => sex == 'F' ? 'Femenino' : (sex == 'M' ? 'Masculino' : '—');

  String get firstName => name.trim().split(' ').first;

  UserAccount copyWith({
    bool? biometric,
    BioMethod? bioMethod,
    double? weightKg,
    int? heightCm,
    int? age,
    String? sex,
    int? dailyGoal,
  }) =>
      UserAccount(
        username: username,
        name: name,
        biometric: biometric ?? this.biometric,
        bioMethod: bioMethod ?? this.bioMethod,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        age: age ?? this.age,
        sex: sex ?? this.sex,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );
}
