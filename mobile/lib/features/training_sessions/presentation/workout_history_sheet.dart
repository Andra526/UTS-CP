import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/training_session_repository.dart';
import '../domain/training_session.dart';

/// Bottom sheet riwayat latihan member (dari laporan sesi PT).
class RiwayatLatihanBottomSheet extends StatelessWidget {
  const RiwayatLatihanBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainingSessionRepository();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Latihan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBuilder<List<TrainingSession>>(
              loader: repo.mine,
              builder: (context, items, reload) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'Belum ada riwayat latihan',
                    subtitle: 'Riwayat muncul setelah PT menyelesaikan sesi Anda.',
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final s = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesi bersama ${s.trainerName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatDate(s.scheduledAt)} • ${s.durationMin} Menit • Intensitas ${s.intensity}/10',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                if (s.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(s.notes, style: const TextStyle(fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              s.attendanceLabel,
                              style: const TextStyle(fontSize: 10, color: Colors.green),
                            ),
                            backgroundColor: Colors.green.shade50,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
