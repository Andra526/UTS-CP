import 'package:flutter/material.dart';

import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/network_thumb.dart';
import '../data/trainer_repository.dart';
import '../domain/trainer.dart';
import 'trainer_detail_screen.dart';

class TrainerListScreen extends StatelessWidget {
  final String gymId;
  final String gymName;
  const TrainerListScreen({super.key, required this.gymId, required this.gymName});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Pilih Personal Trainer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan PT untuk: $gymName',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBuilder<List<Trainer>>(
              loader: () => repo.list(gymId: gymId),
              builder: (context, trainers, reload) {
                if (trainers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Belum ada Personal Trainer di cabang ini.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = trainers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: NetworkThumb(
                          url: trainer.photoUrl ?? '',
                          width: 60,
                          height: 60,
                          fallbackIcon: Icons.person,
                        ),
                        title: Text(
                          trainer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              trainer.specialization,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${trainer.rating} (${trainer.reviewsCount} ulasan)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainerDetailScreen(trainer: trainer),
                            ),
                          );
                        },
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
