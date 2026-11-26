String fmtDuration(int seconds) {
  String t(int n) => n.toString().padLeft(2, '0');
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '${t(h)}:${t(m)}:${t(s)}';
}

String fmtKm(double meters) => (meters / 1000).toStringAsFixed(2);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
