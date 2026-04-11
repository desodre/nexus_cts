String formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

String? formatTimestamp(int? ms) {
  if (ms == null) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return formatDate(dt);
}
