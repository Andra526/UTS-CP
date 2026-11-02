const List<String> _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> _hari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 250000 -> "Rp 250.000"
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp $buffer';
}

/// 2026-10-14 -> "14 Okt 2026"
String formatDate(DateTime d) => '${_two(d.day)} ${_bulan[d.month - 1]} ${d.year}';

/// -> "14:00"
String formatClock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// -> "Selasa, 14 Okt 2026"
String formatLongDate(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${formatDate(d)}';

/// Waktu sesi yang ramah dibaca: "Hari ini, 14:00 - 15:00 WIB".
String formatSessionTime(
  DateTime start,
  int durationMin, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(start.year, start.month, start.day);
  final diff = day.difference(today).inDays;
  final end = start.add(Duration(minutes: durationMin));

  String label;
  if (diff == 0) {
    label = 'Hari ini';
  } else if (diff == 1) {
    label = 'Besok';
  } else if (diff == 2) {
    label = 'Lusa';
  } else {
    label = formatDate(start);
  }
  return '$label, ${formatClock(start)} - ${formatClock(end)} WIB';
}

/// Hitung mundur membership.
String formatCountdown(int totalSeconds) {
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (days > 0) {
    return '$days Hari $hours Jam ${minutes}m ${seconds}d lagi';
  }
  return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
}

/// "Alex Pratama, S.Or." -> "Alex"
String firstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first.replaceAll(',', '');
}
