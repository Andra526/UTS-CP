import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../workout_plans/data/workout_plan_repository.dart';
import '../../workout_plans/domain/workout_plan.dart';
import '../../workout_plans/presentation/workout_tile.dart';

/// Program latihan MEMBER yang sedang login (baca saja + centang selesai).
/// Gerakan disusun oleh PT lewat "Profil Klien > Kelola Program Latihan".
///
/// [onBack] dipakai saat layar ini menjadi tab (kembali ke Beranda). Bila
/// dibuka lewat Navigator.push, tombol back memakai Navigator.pop.
class ExercisesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ExercisesScreen({super.key, this.onBack});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final _repo = WorkoutPlanRepository();
  WorkoutPlan? _plan;
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
      final plan = await _repo.mine();
      if (!mounted) return;
      setState(() {
        _plan = plan;
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

  Future<void> _toggle(WorkoutItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (item.doneToday) {
        await _repo.undoDone(item.id);
      } else {
        await _repo.markDone(item.id);
        messenger.showSnackBar(
          SnackBar(content: Text('${item.exercise} selesai! Tercatat di Progress.')),
        );
      }
      await _load(silent: true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
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
                onPressed: _back,
              )
            : null,
        title: const Text(
          'Program Latihan',
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

    final plan = _plan!;
    if (plan.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(
              icon: Icons.fitness_center,
              title: 'Belum ada program latihan',
              subtitle:
                  'Personal Trainer Anda belum merekomendasikan gerakan. Booking sesi dengan PT untuk mendapatkannya.',
            ),
          ],
        ),
      );
    }

    final byDay = plan.byDay;
    final doneCount = plan.items.where((i) => i.doneToday).length;
    final trainer = plan.items.first.trainerName;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selesai hari ini', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$doneCount / ${plan.items.length} gerakan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plan.items.isEmpty ? 0 : doneCount / plan.items.length,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final entry in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            for (final item in entry.value)
              WorkoutTile(item: item, onToggleDone: () => _toggle(item)),
            const SizedBox(height: 10),
          ],
          if (trainer.isNotEmpty)
            Text(
              'Disusun oleh $trainer. Tarik ke bawah untuk memuat pembaruan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
