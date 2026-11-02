import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/activity_repository.dart';
import '../domain/activity.dart';
import 'activity_tile.dart';

/// Tab "Progress": log aktivitas member (membership, booking, sesi PT,
/// gerakan yang dicentang) beserta ringkasan angka.
///
/// [onBack]: dipakai saat menjadi tab (kembali ke Beranda).
/// Bila dibuka lewat Navigator.push (mis. "Lihat semua" di Beranda) tombol
/// back memakai Navigator.pop.
class ProgressScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProgressScreen({super.key, this.onBack});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repo = ActivityRepository();
  ActivityLog? _log;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final log = await _repo.mine();
      if (!mounted) return;
      setState(() {
        _log = log;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
        return;
      }
      setState(() {
        _loading = false;
        _error = errorMessage(e);
      });
    }
  }

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(height: 10),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBack = widget.onBack != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => widget.onBack != null
                    ? widget.onBack!()
                    : Navigator.maybePop(context),
              )
            : null,
        title: const Text(
          'Progress & Log Aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const AppLoading();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);

    final log = _log!;
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _stat('Sesi PT selesai', log.stats.sessionsCompleted, Icons.verified_outlined),
              const SizedBox(width: 10),
              _stat('Gerakan minggu ini', log.stats.workoutsThisWeek, Icons.local_fire_department_outlined),
              const SizedBox(width: 10),
              _stat('Total gerakan', log.stats.totalWorkouts, Icons.fitness_center),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (log.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.history,
                title: 'Belum ada aktivitas',
                subtitle:
                    'Beli membership, booking PT, atau centang gerakan latihan — semuanya tercatat di sini.',
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < log.items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                    ActivityTile(item: log.items[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
