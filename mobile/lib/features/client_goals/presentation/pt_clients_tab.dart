import 'package:flutter/material.dart';

import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/network_thumb.dart';
import '../../bookings/presentation/goal_chip.dart';
import '../data/client_repository.dart';
import '../domain/client_goal.dart';
import 'pt_client_detail_screen.dart';

/// Kartu klien (dipakai di Dashboard & tab Klien).
class PtClientCard extends StatelessWidget {
  final PtClient client;
  final VoidCallback? onChanged;
  const PtClientCard({super.key, required this.client, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final percent = (client.progress * 100).round();
    final subtitle = client.goal == null || client.goal!.description.isEmpty
        ? '${client.completedSessions}/${client.totalSessions} sesi selesai'
        : client.goal!.description;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          NetworkThumb(
            url: client.photoUrl ?? '',
            width: 54,
            height: 54,
            fallbackIcon: Icons.person,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GoalChip(goalType: client.goalType),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: client.progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: client.isActive ? Colors.black : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percent%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PtClientDetailScreen(client: client),
                ),
              );
              onChanged?.call();
            },
            child: const Text('Kelola', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class PtClientsTab extends StatefulWidget {
  const PtClientsTab({super.key});

  @override
  State<PtClientsTab> createState() => _PtClientsTabState();
}

class _PtClientsTabState extends State<PtClientsTab> {
  final _repo = ClientRepository();
  String _query = '';
  String _filter = 'Semua'; // Semua | Aktif | Selesai

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Klien Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari nama klien...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final label in const ['Semua', 'Aktif', 'Selesai'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == label,
                      showCheckmark: false,
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _filter == label ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBuilder<List<PtClient>>(
              loader: _repo.mine,
              builder: (context, all, reload) {
                final clients = all.where((c) {
                  final matchQuery = c.name.toLowerCase().contains(_query.toLowerCase());
                  final matchFilter =
                      _filter == 'Semua' ||
                      (_filter == 'Aktif' && c.isActive) ||
                      (_filter == 'Selesai' && !c.isActive);
                  return matchQuery && matchFilter;
                }).toList();

                if (clients.isEmpty) {
                  return const EmptyState(
                    icon: Icons.group_outlined,
                    title: 'Klien tidak ditemukan.',
                    subtitle: 'Klien muncul setelah ada request sesi dari member.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: clients.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        PtClientCard(client: clients[index], onChanged: reload),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
