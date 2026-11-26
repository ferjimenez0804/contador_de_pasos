/// Datos corporales que personalizan calorías, zancada e IMC.
class BodyData {
  final double weightKg;
  final int heightCm;
  final int age;
  final String sex; // 'M' o 'F'
  final int dailyGoal;

  const BodyData({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.dailyGoal,
  });
}
