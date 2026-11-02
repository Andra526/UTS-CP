import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';
import 'booking_status_chip.dart';
import 'goal_chip.dart';

/// Daftar sesi/booking milik member.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Future<void> _cancel(
    BuildContext context,
    Booking booking,
    VoidCallback reload,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan sesi?'),
        content: Text('Sesi dengan ${booking.trainerName} akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await BookingRepository().cancel(booking.id);
      messenger.showSnackBar(const SnackBar(content: Text('Sesi dibatalkan.')));
      reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = BookingRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Sesi Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: AsyncBuilder<List<Booking>>(
        loader: repo.mine,
        builder: (context, bookings, reload) {
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Belum ada sesi',
              subtitle: 'Pilih PT dan booking sesi latihan pertama Anda.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final cancellable =
                    b.status == BookingStatus.pending ||
                    b.status == BookingStatus.accepted;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b.trainerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          BookingStatusChip(status: b.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSessionTime(b.scheduledAt, b.durationMin),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GoalChip(goalType: b.goalType),
                      ),
                      if (b.customGoal.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Tujuan: ${b.customGoal}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                      if (b.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(b.note, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      if (cancellable) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _cancel(context, b, reload),
                            child: const Text('Batalkan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
