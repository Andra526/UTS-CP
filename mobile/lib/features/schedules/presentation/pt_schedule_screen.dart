import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../personal_trainers/data/trainer_repository.dart';
import '../../personal_trainers/domain/trainer.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_slot.dart';

class PtScheduleScreen extends StatelessWidget {
  const PtScheduleScreen({super.key});

  Future<(List<ScheduleSlot>, Trainer)> _load() async {
    final slots = await ScheduleRepository().mine();
    final me = await TrainerRepository().me();
    return (slots, me);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _addScheduleDialog(BuildContext context, VoidCallback reload) async {
    final messenger = ScaffoldMessenger.of(context);
    String day = kDayNames.first;
    TimeOfDay? start;
    TimeOfDay? end;
    String? error;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Slot Jadwal Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: day,
                  isExpanded: true,
                  items: kDayNames
                      .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => day = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: start ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) setDialogState(() => start = picked);
                        },
                        child: Text(start == null ? 'Jam mulai' : _fmt(start!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: end ?? const TimeOfDay(hour: 11, minute: 0),
                          );
                          if (picked != null) setDialogState(() => end = picked);
                        },
                        child: Text(end == null ? 'Jam selesai' : _fmt(end!)),
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
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
                        if (start == null || end == null) {
                          setDialogState(() => error = 'Pilih jam mulai dan jam selesai.');
                          return;
                        }
                        final s = _fmt(start!);
                        final e = _fmt(end!);
                        if (s.compareTo(e) >= 0) {
                          setDialogState(() => error = 'Jam selesai harus setelah jam mulai.');
                          return;
                        }
                        setDialogState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await ScheduleRepository().create(day: day, startTime: s, endTime: e);
                          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                        } catch (err) {
                          setDialogState(() {
                            saving = false;
                            error = errorMessage(err);
                          });
                        }
                      },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Jadwal berhasil ditambahkan!')));
      reload();
    }
  }

  Future<void> _delete(
    BuildContext context,
    ScheduleSlot slot,
    VoidCallback reload,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ScheduleRepository().remove(slot.id);
      messenger.showSnackBar(const SnackBar(content: Text('Jadwal berhasil dihapus')));
      reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBuilder<(List<ScheduleSlot>, Trainer)>(
      loader: _load,
      builder: (context, data, reload) {
        final slots = data.$1;
        final trainer = data.$2;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            title: const Text(
              'Kelola Jadwal & Kalender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                onPressed: () => _addScheduleDialog(context, reload),
                tooltip: 'Tambah Jadwal',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal Ketersediaan Sesi Latihan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Klien dapat melakukan booking berdasarkan slot waktu di bawah ini.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: slots.isEmpty
                      ? const EmptyState(
                          icon: Icons.calendar_today_outlined,
                          title: 'Belum ada slot jadwal',
                          subtitle: 'Ketuk tombol + untuk menambah slot.',
                        )
                      : ListView.builder(
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final item = slots[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.calendar_month, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.day,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.timeLabel,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          trainer.gymName,
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(context, item, reload),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
