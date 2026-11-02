import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/workout_plan_repository.dart';
import '../domain/workout_plan.dart';
import 'workout_tile.dart';

/// PT menyusun program latihan SATU klien. Klien langsung melihatnya di
/// tab "Latihan" pada aplikasinya.
class PtClientWorkoutScreen extends StatelessWidget {
  final String clientId;
  final String clientName;
  const PtClientWorkoutScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  static const _days = [
    'Hari 1', 'Hari 2', 'Hari 3', 'Hari 4', 'Hari 5', 'Hari 6', 'Hari 7', 'Hari 8',
  ];

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
    VoidCallback reload,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
      reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  Future<void> _openForm(
    BuildContext context,
    WorkoutPlanRepository repo,
    VoidCallback reload, {
    WorkoutItem? item,
    String? defaultDay,
  }) async {
    final r = await showDialog<_WorkoutFormResult>(
      context: context,
      builder: (_) => _WorkoutFormDialog(item: item, days: _days, defaultDay: defaultDay),
    );
    if (r == null || !context.mounted) return;
    if (item == null) {
      await _run(
        context,
        () => repo.add(
          clientId,
          dayLabel: r.dayLabel,
          exercise: r.exercise,
          sets: r.sets,
          reps: r.reps,
          restSec: r.restSec,
          note: r.note,
        ),
        'Gerakan ditambahkan. Klien langsung melihatnya.',
        reload,
      );
    } else {
      await _run(
        context,
        () => repo.update(
          item.id,
          dayLabel: r.dayLabel,
          exercise: r.exercise,
          sets: r.sets,
          reps: r.reps,
          restSec: r.restSec,
          note: r.note,
        ),
        'Gerakan diperbarui.',
        reload,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WorkoutPlanRepository repo,
    WorkoutItem item,
    VoidCallback reload,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus gerakan?'),
        content: Text('"${item.exercise}" akan dihapus dari program $clientName.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () => repo.remove(item.id), 'Gerakan dihapus.', reload);
  }

  @override
  Widget build(BuildContext context) {
    final repo = WorkoutPlanRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Program Latihan: $clientName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: AsyncBuilder<WorkoutPlan>(
        loader: () => repo.forClient(clientId),
        builder: (context, plan, reload) {
          final byDay = plan.byDay;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    if (plan.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: EmptyState(
                          icon: Icons.fitness_center,
                          title: 'Belum ada program untuk $clientName',
                          subtitle:
                              'Ketuk "Tambah Gerakan" untuk merekomendasikan gerakan latihan.',
                        ),
                      )
                    else
                      for (final entry in byDay.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _openForm(context, repo, reload, defaultDay: entry.key),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Gerakan'),
                              ),
                            ],
                          ),
                        ),
                        for (final item in entry.value)
                          WorkoutTile(
                            item: item,
                            onEdit: () => _openForm(context, repo, reload, item: item),
                            onDelete: () => _confirmDelete(context, repo, item, reload),
                          ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  heroTag: 'add-workout',
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  onPressed: () => _openForm(context, repo, reload),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Gerakan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutFormResult {
  final String dayLabel;
  final String exercise;
  final int sets;
  final String reps;
  final int? restSec;
  final String note;
  const _WorkoutFormResult(
    this.dayLabel,
    this.exercise,
    this.sets,
    this.reps,
    this.restSec,
    this.note,
  );
}

class _WorkoutFormDialog extends StatefulWidget {
  final WorkoutItem? item;
  final List<String> days;
  final String? defaultDay;
  const _WorkoutFormDialog({required this.item, required this.days, this.defaultDay});

  @override
  State<_WorkoutFormDialog> createState() => _WorkoutFormDialogState();
}

class _WorkoutFormDialogState extends State<_WorkoutFormDialog> {
  late final TextEditingController _day;
  late final TextEditingController _exercise;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _rest;
  late final TextEditingController _note;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _day = TextEditingController(text: i?.dayLabel ?? widget.defaultDay ?? widget.days.first);
    _exercise = TextEditingController(text: i?.exercise ?? '');
    _sets = TextEditingController(text: i == null ? '3' : '${i.sets}');
    _reps = TextEditingController(text: i?.reps ?? '10-12');
    _rest = TextEditingController(text: i?.restSec == null ? '60' : '${i!.restSec}');
    _note = TextEditingController(text: i?.note ?? '');
  }

  @override
  void dispose() {
    _day.dispose();
    _exercise.dispose();
    _sets.dispose();
    _reps.dispose();
    _rest.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final day = _day.text.trim();
    final exercise = _exercise.text.trim();
    final reps = _reps.text.trim();
    final sets = int.tryParse(_sets.text.trim());
    final restText = _rest.text.trim();
    final rest = restText.isEmpty ? null : int.tryParse(restText);

    if (day.length < 2 || exercise.length < 2) {
      setState(() => _error = 'Isi hari/sesi dan nama gerakan.');
      return;
    }
    if (sets == null || sets < 1 || reps.isEmpty) {
      setState(() => _error = 'Set harus angka (min. 1) dan repetisi tidak boleh kosong.');
      return;
    }
    if (restText.isNotEmpty && rest == null) {
      setState(() => _error = 'Waktu istirahat harus berupa angka (detik).');
      return;
    }
    Navigator.pop(
      context,
      _WorkoutFormResult(day, exercise, sets, reps, rest, _note.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Gerakan' : 'Ubah Gerakan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _day,
              decoration: const InputDecoration(labelText: 'Hari / sesi (mis. Hari 1 - Dada)'),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final d in widget.days)
                  ActionChip(
                    label: Text(d, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _day.text = d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exercise,
              decoration: const InputDecoration(labelText: 'Nama gerakan (mis. Bench Press)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reps,
                    decoration: const InputDecoration(labelText: 'Repetisi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rest,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Istirahat (detik, opsional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan teknik (opsional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
