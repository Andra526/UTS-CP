import 'package:flutter_test/flutter_test.dart';
import 'package:gymfit/core/utils/formatters.dart';
import 'package:gymfit/features/bookings/domain/booking.dart';
import 'package:gymfit/features/gym_selection/domain/gym.dart';

void main() {
  group('formatters', () {
    test('formatRupiah memberi titik ribuan', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(999), 'Rp 999');
      expect(formatRupiah(250000), 'Rp 250.000');
      expect(formatRupiah(2400000), 'Rp 2.400.000');
    });

    test('formatCountdown', () {
      expect(formatCountdown(3661), '01:01:01');
      expect(formatCountdown(90061), '1 Hari 1 Jam 1m 1d lagi');
    });

    test('formatDate & formatClock', () {
      expect(formatDate(DateTime(2026, 10, 14)), '14 Okt 2026');
      expect(formatClock(DateTime(2026, 10, 14, 9, 5)), '09:05');
    });

    test('formatSessionTime memakai Hari ini / Besok', () {
      final now = DateTime(2026, 10, 26, 9, 0);
      expect(
        formatSessionTime(DateTime(2026, 10, 26, 16, 0), 60, now: now),
        'Hari ini, 16:00 - 17:00 WIB',
      );
      expect(
        formatSessionTime(DateTime(2026, 10, 27, 14, 0), 60, now: now),
        'Besok, 14:00 - 15:00 WIB',
      );
    });

    test('firstName', () {
      expect(firstName('Alex Pratama, S.Or.'), 'Alex');
      expect(firstName('  '), '');
    });
  });

  group('model parsing', () {
    test('Booking.fromJson membaca relasi client & trainer', () {
      final b = Booking.fromJson({
        'id': 'b1',
        'status': 'PENDING',
        'scheduledAt': '2026-10-27T07:00:00.000Z',
        'durationMin': 60,
        'client': {'id': 'c1', 'name': 'Budi'},
        'trainer': {
          'id': 't1',
          'user': {'name': 'Alex'},
        },
      });
      expect(b.clientName, 'Budi');
      expect(b.trainerName, 'Alex');
      expect(b.hasReport, false);
    });

    test('Gym.fromJson tahan terhadap field kosong', () {
      final g = Gym.fromJson({'id': 'g1', 'name': 'GymFit'});
      expect(g.plans, isEmpty);
      expect(g.rating, 0);
    });

    test('GymPlan.periodLabel', () {
      GymPlan plan(int days) => GymPlan(
        id: 'p',
        name: 'x',
        price: 1,
        durationDays: days,
        note: '',
        isPopular: false,
      );
      expect(plan(30).periodLabel, '/bulan');
      expect(plan(365).periodLabel, '/tahun');
      expect(plan(1).periodLabel, '/hari');
    });
  });
}
