import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/network_thumb.dart';
import '../../authentication/presentation/logout.dart';
import '../../authentication/presentation/session_controller.dart';
import '../../gym_selection/data/gym_repository.dart';
import '../../gym_selection/domain/gym.dart';

/// Beranda Admin Gym: lihat & ubah informasi cabang yang dikelola.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _edit(BuildContext context, Gym gym, VoidCallback reload) async {
    final messenger = ScaffoldMessenger.of(context);
    final address = TextEditingController(text: gym.address);
    final hours = TextEditingController(text: gym.openHours);
    final phone = TextEditingController(text: gym.phone);
    String? error;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ubah Info Cabang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: address, decoration: const InputDecoration(labelText: 'Alamat')),
                TextField(controller: hours, decoration: const InputDecoration(labelText: 'Jam operasional')),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await GymRepository().update(
                          gym.id,
                          address: address.text.trim(),
                          openHours: hours.text.trim(),
                          phone: phone.text.trim(),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          error = errorMessage(e);
                        });
                      }
                    },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    address.dispose();
    hours.dispose();
    phone.dispose();

    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Info cabang diperbarui!')));
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymId = session.user?.managedGymId;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Admin Gym',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => performLogout(context),
          ),
        ],
      ),
      body: gymId == null
          ? const EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'Akun ini belum ditautkan ke cabang gym.',
            )
          : AsyncBuilder<Gym>(
              loader: () => GymRepository().get(gymId),
              builder: (context, gym, reload) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    NetworkThumb(url: gym.imageUrl, width: double.infinity, height: 170, radius: 16),
                    const SizedBox(height: 16),
                    Text(gym.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${gym.memberCount} member • ${gym.trainerCount} personal trainer',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text('Alamat'),
                            subtitle: Text(gym.address),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('Jam Operasional'),
                            subtitle: Text(gym.openHours),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Telepon'),
                            subtitle: Text(gym.phone),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _edit(context, gym, reload),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Ubah Info Cabang', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
