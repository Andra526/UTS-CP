import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../training_sessions/presentation/pt_session_report_screen.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';
import 'booking_status_chip.dart';
import 'goal_chip.dart';

class PtSessionManagementScreen extends StatelessWidget {
  const PtSessionManagementScreen({super.key});

  Future<void> _respond(
    BuildContext context,
    Booking booking,
    bool accept,
    VoidCallback reload,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BookingRepository().respond(booking.id, accept: accept);
      messenger.showSnackBar(
        SnackBar(content: Text('Request sesi berhasil ${accept ? 'diterima' : 'ditolak'}!')),
      );
      reload();
    } catch (e) {
      // Mis. bentrok jadwal dengan sesi lain (409)
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  Future<void> _openReport(
    BuildContext context,
    Booking booking,
    VoidCallback reload,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PtSessionReportScreen(booking: booking),
      ),
    );
    if (saved == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = BookingRepository();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text(
            'Manajemen Sesi & Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Request Masuk'),
              Tab(text: 'Sesi Aktif'),
            ],
          ),
        ),
        body: AsyncBuilder<List<Booking>>(
          loader: () => repo.forTrainer(),
          builder: (context, all, reload) {
            final requests = all
                .where((b) => b.status == BookingStatus.pending)
                .toList();
            final active = all
                .where((b) => b.status == BookingStatus.accepted)
                .toList();

            return TabBarView(
              children: [
                _list(
                  requests,
                  const EmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Tidak ada request baru',
                  ),
                  (b) => _requestCard(context, b, reload),
                  reload,
                ),
                _list(
                  active,
                  const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Belum ada sesi aktif',
                  ),
                  (b) => _activeCard(context, b, reload),
                  reload,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(
    List<Booking> items,
    Widget empty,
    Widget Function(Booking) card,
    VoidCallback reload,
  ) {
    if (items.isEmpty) return empty;
    return RefreshIndicator(
      onRefresh: () async => reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => card(items[index]),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
  );

  Widget _requestCard(BuildContext context, Booking b, VoidCallback reload) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _respond(context, b, false, reload),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => _respond(context, b, true, reload),
                  child: const Text('Terima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeCard(BuildContext context, Booking b, VoidCallback reload) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(b.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              BookingStatusChip(status: b.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatSessionTime(b.scheduledAt, b.durationMin),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              // Wajib mengisi Laporan Sesi sebelum ditandai Selesai (FR-PT13)
              onPressed: () => _openReport(context, b, reload),
              child: const Text('Isi Laporan & Tandai Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}
