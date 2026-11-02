import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/network_thumb.dart';
import '../../memberships/presentation/payment_dialog.dart';
import '../../personal_trainers/presentation/trainer_list_screen.dart';
import '../domain/gym.dart';

class GymDetailScreen extends StatelessWidget {
  final Gym gym;
  const GymDetailScreen({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Detail Gym',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkThumb(
              url: gym.imageUrl,
              width: double.infinity,
              height: 190,
              radius: 16,
            ),
            if (gym.images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: gym.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => NetworkThumb(
                    url: gym.images[i],
                    width: 96,
                    height: 72,
                    radius: 10,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              gym.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${gym.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${gym.memberCount} member',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.location_on_outlined, 'Alamat', gym.address),
                  const SizedBox(height: 12),
                  _infoRow(Icons.access_time, 'Jam Operasional', gym.openHours),
                  const SizedBox(height: 12),
                  _infoRow(Icons.phone_outlined, 'Telepon', gym.phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fasilitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in gym.facilities)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon, size: 16, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(f.label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Paket Membership',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final plan in gym.plans) ...[
              _PlanCard(plan: plan, gym: gym),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainerListScreen(
                      gymId: gym.id,
                      gymName: gym.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.sports_gymnastics, size: 20),
              label: Text(
                'Lihat Personal Trainer (${gym.trainerCount})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final GymPlan plan;
  final Gym gym;
  const _PlanCard({required this.plan, required this.gym});

  Future<void> _buy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showPaymentDialog(context, plan: plan, gymName: gym.name);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Pembayaran berhasil! Membership ${plan.name} aktif.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? Colors.black : Colors.grey.shade200,
          width: plan.isPopular ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(plan.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (plan.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Populer', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatRupiah(plan.price)} • ${plan.durationDays} hari',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(plan.note, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
            ),
            onPressed: () => _buy(context),
            child: const Text('Pilih', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
