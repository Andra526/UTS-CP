class Roles {
  static const String member = 'MEMBER';
  static const String trainer = 'TRAINER';
  static const String admin = 'ADMIN';
}

class BookingStatus {
  static const String pending = 'PENDING';
  static const String accepted = 'ACCEPTED';
  static const String rejected = 'REJECTED';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Menunggu';
      case accepted:
        return 'Diterima';
      case rejected:
        return 'Ditolak';
      case completed:
        return 'Selesai';
      case cancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

const List<String> kDayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
