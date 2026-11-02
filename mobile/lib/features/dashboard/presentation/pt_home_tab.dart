import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../authentication/presentation/session_controller.dart';
import '../../client_goals/data/client_repository.dart';
import '../../client_goals/domain/client_goal.dart';
import '../../client_goals/presentation/pt_clients_tab.dart';
import '../../personal_trainers/data/trainer_repository.dart';
import '../../personal_trainers/domain/trainer.dart';

class PtHomeTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const PtHomeTab({super.key, required this.onNavigate});

  Future<(PtDashboard, List<PtClient>)> _load() async {
    final dashboard = await TrainerRepository().dashboard();
    final clients = await ClientRepository().mine();
    return (dashboard, clients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: AsyncBuilder<(PtDashboard, List<PtClient>)>(
          loader: _load,
          builder: (context, data, reload) {
            final dashboard = data.$1;
            final activeClients = data.$2.where((c) => c.isActive).take(3).toList();
            final next = dashboard.nextSession;

            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sapaan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: session,
                                builder: (context, child) {
                                  return Text(
                                    'Halo, ${session.user?.name ?? dashboard.trainer.name}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dashboard.trainer.gymName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'Role: PT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Statistik
                    Row(
                      children: [
                        Expanded(
                          child: _statCard('Klien Aktif', '${dashboard.activeClients} Orang', Icons.group, Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Request Menunggu',
                            '${dashboard.pendingRequests} Request',
                            Icons.mark_email_unread,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard('Sesi Hari Ini', '${dashboard.todaySessions} Sesi', Icons.alarm, Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Rating', '${dashboard.rating} / 5', Icons.star, Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Banner sesi terdekat
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sesi Latihan Terdekat',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            next == null ? 'Belum ada sesi terjadwal' : next.clientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            next == null
                                ? 'Terima request dari klien untuk mengisi jadwal.'
                                : formatSessionTime(next.scheduledAt, next.durationMin),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                    ),
                                    // Menu & nutrisi selalu per klien: pilih klien dulu.
                                    onPressed: () => onNavigate(1),
                                    child: const Text(
                                      'Menu Klien',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white54),
                                    ),
                                    onPressed: () => onNavigate(2),
                                    child: const Text('Lihat Sesi', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Klien aktif
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Klien Bimbingan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => onNavigate(1),
                          child: const Text('Lihat semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (activeClients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Belum ada klien aktif.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    for (final client in activeClients) ...[
                      PtClientCard(client: client, onChanged: reload),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
