import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

class ScheduleSessionResult {
  final DateTime start;
  final int durationMin;
  final String note;
  const ScheduleSessionResult(this.start, this.durationMin, this.note);
}

/// PT memilih hari + jam sesi untuk klien.
class ScheduleSessionDialog extends StatefulWidget {
  final String clientName;
  const ScheduleSessionDialog({super.key, required this.clientName});

  @override
  State<ScheduleSessionDialog> createState() => _ScheduleSessionDialogState();
}

class _ScheduleSessionDialogState extends State<ScheduleSessionDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 60;
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_date == null || _time == null) {
      setState(() => _error = 'Pilih hari dan jam sesi.');
      return;
    }
    final start = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    if (!start.isAfter(DateTime.now())) {
      setState(() => _error = 'Waktu sesi harus di masa depan.');
      return;
    }
    Navigator.pop(context, ScheduleSessionResult(start, _duration, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _time == null
        ? 'Pilih jam'
        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text('Jadwalkan Sesi: ${widget.clientName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text(_date == null ? 'Pilih hari / tanggal' : formatLongDate(_date!)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(timeLabel),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _duration,
              isExpanded: true,
              items: const [30, 45, 60, 90]
                  .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m menit')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _duration = v);
              },
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
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
          child: const Text('Jadwalkan'),
        ),
      ],
    );
  }
}
