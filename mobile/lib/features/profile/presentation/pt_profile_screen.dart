import 'package:flutter/material.dart';

import '../../../shared/widgets/async_builder.dart';
import '../../authentication/presentation/logout.dart';
import '../../authentication/presentation/session_controller.dart';
import '../../personal_trainers/data/trainer_repository.dart';
import '../../personal_trainers/domain/trainer.dart';
import 'edit_profile_dialog.dart';

class PtProfileScreen extends StatelessWidget {
  const PtProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Profil Personal Trainer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: AsyncBuilder<Trainer>(
        loader: TrainerRepository().me,
        builder: (context, trainer, reload) {
          return AnimatedBuilder(
            animation: session,
            builder: (context, child) {
              final user = session.user;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.fitness_center, size: 32, color: Colors.black87),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? trainer.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Personal Trainer',
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox('${trainer.experienceYears} Thn', 'Pengalaman'),
                      const SizedBox(width: 10),
                      _statBox('${trainer.reviewsCount}', 'Ulasan'),
                      const SizedBox(width: 10),
                      _statBox('${trainer.rating}', 'Rating'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Nama'),
                          subtitle: Text(user?.name ?? trainer.name),
                          trailing: const Icon(Icons.edit, size: 18),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await showEditProfileDialog(context);
                            if (ok) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Nama berhasil diperbarui!')),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        ListTile(
                          leading: const Icon(Icons.workspace_premium_outlined),
                          title: const Text('Spesialisasi'),
                          subtitle: Text(trainer.specialization),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Cabang Gym'),
                          subtitle: Text(trainer.gymName),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => performLogout(context),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
