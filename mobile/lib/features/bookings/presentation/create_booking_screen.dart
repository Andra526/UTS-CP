import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../personal_trainers/domain/trainer.dart';
import '../../schedules/data/schedule_repository.dart';
import '../../schedules/domain/schedule_slot.dart';
import '../../session_packages/data/session_package_repository.dart';
import '../../session_packages/domain/session_package.dart';
import '../../session_packages/presentation/session_quota_card.dart';
import '../data/booking_repository.dart';
import '../domain/goal_type.dart';

class CreateBookingScreen extends StatefulWidget {
  final Trainer trainer;
  const CreateBookingScreen({super.key, required this.trainer});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _bookingRepo = BookingRepository();
  final _scheduleRepo = ScheduleRepository();
  final _note = TextEditingController();
  final _customGoal = TextEditingController();
  final _packageRepo = SessionPackageRepository();
  SessionPackage? _quota;

  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 60;
  String _goal = 'GENERAL';
  bool _submitting = false;
  String? _error;
  List<ScheduleSlot> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadQuota();
  }

  @override
  void dispose() {
    _note.dispose();
    _customGoal.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    try {
      final slots = await _scheduleRepo.byTrainer(widget.trainer.id);
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (_) {
      // Jadwal hanya informasi tambahan; abaikan jika gagal dimuat.
    }
  }

  Future<void> _loadQuota() async {
    try {
      final q = await _packageRepo.withTrainer(widget.trainer.id);
      if (!mounted) return;
      setState(() => _quota = q);
    } catch (_) {
      // Info kuota hanya tambahan; server tetap memvalidasi saat kirim.
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
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

  Future<void> _submit() async {
    if (_quota != null && !_quota!.canBook) {
      setState(() => _error = _quota!.isExhausted
          ? 'Kuota ${_quota!.total} sesi dengan PT ini sudah habis. Minta PT menambah kuota.'
          : 'Sisa sesi Anda sudah terpakai oleh booking yang menunggu/terjadwal.');
      return;
    }
    if (_date == null || _time == null) {
      setState(() => _error = 'Pilih tanggal dan jam sesi terlebih dahulu.');
      return;
    }
    final start = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (!start.isAfter(DateTime.now())) {
      setState(() => _error = 'Waktu sesi harus di masa depan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _bookingRepo.create(
        trainerId: widget.trainer.id,
        scheduledAt: start,
        durationMin: _duration,
        note: _note.text,
        goalType: _goal,
        customGoal: _customGoal.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request terkirim! Menunggu konfirmasi PT.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null ? 'Pilih tanggal' : formatLongDate(_date!);
    final timeLabel = _time == null
        ? 'Pilih jam'
        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Booking Sesi Latihan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.fitness_center, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trainer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          widget.trainer.gymName,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_quota != null)
              SessionQuotaCard(pkg: _quota!, title: 'Kuota sesi dengan PT ini')
            else
              const Text(
                'Setiap PT memberi paket 8 sesi latihan.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 20),
            const Text(
              'Jadwal ketersediaan PT',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_slots.isEmpty)
              const Text(
                'PT belum mengatur jadwal; Anda tetap bisa mengajukan waktu pilihan.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _slots)
                    Chip(
                      label: Text('${s.day} ${s.startTime}-${s.endTime}', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              'Pilih waktu sesi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(dateLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(timeLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Durasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _duration,
                  isExpanded: true,
                  items: const [30, 45, 60, 90]
                      .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m menit')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _duration = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paket tujuan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'PT akan menyusun program dan pola makan sesuai tujuan Anda.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in goalTypes)
                  ChoiceChip(
                    avatar: Icon(
                      g.icon,
                      size: 16,
                      color: _goal == g.value ? Colors.white : Colors.black87,
                    ),
                    label: Text(g.label),
                    selected: _goal == g.value,
                    selectedColor: Colors.black,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _goal == g.value ? Colors.white : Colors.black87,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _goal = g.value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _customGoal,
              label: 'Tujuan lain / program yang diinginkan (opsional)',
              icon: Icons.flag_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            const Text(
              'Isi jika tidak ada pilihan di atas yang cocok. Contoh: persiapan lomba lari 10K.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _note,
              label: 'Catatan untuk PT (opsional)',
              icon: Icons.notes,
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Kirim Request Sesi',
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
