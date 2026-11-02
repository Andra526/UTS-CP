import 'package:flutter/material.dart';

import '../../authentication/presentation/logout.dart';
import '../../authentication/presentation/session_controller.dart';
import '../../memberships/data/membership_repository.dart';
import '../../memberships/domain/membership.dart';
import '../../training_sessions/presentation/workout_history_sheet.dart';
import 'edit_profile_dialog.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan hadir di pembaruan berikutnya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Pengguna',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Kartu informasi akun
              AnimatedBuilder(
                animation: session,
                builder: (context, child) {
                  final user = session.user;
                  return Container(
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
                          child: Icon(Icons.person, size: 40, color: Colors.black87),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? '-',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '-',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              const _MembershipBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Pengaturan Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.history,
                      title: 'Riwayat Latihan',
                      subtitle: 'Lihat catatan sesi latihan sebelumnya',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => const RiwayatLatihanBottomSheet(),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _menuItem(
                      icon: Icons.person_outline,
                      title: 'Data Pribadi',
                      subtitle: 'Ubah nama dan nomor HP',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await showEditProfileDialog(context);
                        if (ok) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Data pribadi berhasil diperbarui!')),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _menuItem(
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan Aplikasi',
                      subtitle: 'Notifikasi, bahasa, dan tema',
                      onTap: () => _soon(context, 'Pengaturan aplikasi'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _menuItem(
                      icon: Icons.help_outline,
                      title: 'Bantuan & Dukungan',
                      subtitle: 'Hubungi layanan pelanggan GymFit',
                      onTap: () => _soon(context, 'Bantuan & dukungan'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => performLogout(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

/// Lencana status membership (memuat dari server).
class _MembershipBadge extends StatefulWidget {
  const _MembershipBadge();

  @override
  State<_MembershipBadge> createState() => _MembershipBadgeState();
}

class _MembershipBadgeState extends State<_MembershipBadge> {
  late final Future<Membership?> _future = MembershipRepository().active();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Membership?>(
      future: _future,
      builder: (context, snapshot) {
        String label;
        if (snapshot.connectionState != ConnectionState.done) {
          label = 'Memuat...';
        } else if (snapshot.hasError || snapshot.data == null) {
          label = 'Belum Member';
        } else {
          label = 'Member Aktif (${snapshot.data!.planName})';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
        );
      },
    );
  }
}
