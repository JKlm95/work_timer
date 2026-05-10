/// Czytelny format np. „2 h 05 min” / „42 min”.
String formatDurationHm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h <= 0) return '$m min';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}
