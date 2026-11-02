import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../bookings/domain/booking.dart';
import '../data/training_session_repository.dart';

class PtSessionReportScreen extends StatefulWidget {
  final Booking booking;
  const PtSessionReportScreen({super.key, required this.booking});

  @override
  State<PtSessionReportScreen> createState() => _PtSessionReportScreenState();
}

class _PtSessionReportScreenState extends State<PtSessionReportScreen> {
  final _repo = TrainingSessionRepository();
  final TextEditingController notesController = TextEditingController();

  // label tampilan -> nilai di server
  static const Map<String, String> _attendanceValues = {
    'Hadir': 'HADIR',
    'Terlambat': 'TERLAMBAT',
    'Tidak Hadir': 'TIDAK_HADIR',
  };

  String attendance = 'Hadir';
  double intensity = 8.0;
  bool _saving = false;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.create(
        bookingId: widget.booking.id,
        attendance: _attendanceValues[attendance] ?? 'HADIR',
        intensity: intensity.round(),
        notes: notesController.text,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Laporan sesi berhasil disimpan dan sesi ditandai Selesai!'),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Laporan Sesi: ${b.clientName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            Text(
              formatSessionTime(b.scheduledAt, b.durationMin),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text('Kehadiran Klien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: attendance,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _attendanceValues.keys
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => attendance = val);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Intensitas Latihan (Skala 1 - 10)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Slider(
              value: intensity,
              min: 1,
              max: 10,
              divisions: 9,
              label: intensity.round().toString(),
              activeColor: Colors.black,
              onChanged: (val) => setState(() => intensity = val),
            ),
            const SizedBox(height: 20),
            const Text('Ringkasan & Catatan PT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan performa, kondisi klien, dan tugas berikutnya...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Simpan Laporan & Selesaikan Sesi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
