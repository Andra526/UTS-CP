import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../bookings/domain/goal_type.dart';
import '../../bookings/data/booking_repository.dart';
import '../../meal_plans/presentation/pt_client_nutrition_screen.dart';
import '../../session_packages/data/session_package_repository.dart';
import '../../session_packages/domain/session_package.dart';
import '../../session_packages/presentation/schedule_session_dialog.dart';
import '../../session_packages/presentation/session_quota_card.dart';
import '../../workout_plans/presentation/pt_client_workout_screen.dart';
import '../data/client_repository.dart';
import '../domain/client_goal.dart';

class PtClientDetailScreen extends StatefulWidget {
  final PtClient client;
  const PtClientDetailScreen({super.key, required this.client});

  @override
  State<PtClientDetailScreen> createState() => _PtClientDetailScreenState();
}

class _PtClientDetailScreenState extends State<PtClientDetailScreen> {
  final _repo = ClientRepository();
  final _packageRepo = SessionPackageRepository();
  SessionPackage? _pkg;

  // Target Program Klien (FR-PT10)
  late String currentTarget;
  // Penyesuaian Nutrisi Khusus Klien (FR-PT11)
  int? customCalories;
  int? customProtein;

  @override
  void initState() {
    super.initState();
    final goal = widget.client.goal;
    currentTarget = goal?.description ?? '';
    customCalories = goal?.targetCalories;
    customProtein = goal?.targetProtein;
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    try {
      final p = await _packageRepo.forClient(widget.client.id);
      if (!mounted) return;
      setState(() => _pkg = p);
    } catch (_) {}
  }

  Future<void> _scheduleSession() async {
    final r = await showDialog<ScheduleSessionResult>(
      context: context,
      builder: (_) => ScheduleSessionDialog(clientName: widget.client.name),
    );
    if (r == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BookingRepository().scheduleByTrainer(
        clientId: widget.client.id,
        scheduledAt: r.start,
        durationMin: r.durationMin,
        note: r.note,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Sesi dijadwalkan. Klien langsung melihatnya.')));
      _loadPackage();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  Future<void> _addQuota() async {
    final controller = TextEditingController(text: '8');
    final amount = await showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Tambah Kuota Sesi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah sesi tambahan'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(d, int.tryParse(controller.text.trim())),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (amount == null || amount < 1 || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final p = await _packageRepo.addQuota(widget.client.id, amount);
      if (!mounted) return;
      setState(() => _pkg = p);
      messenger.showSnackBar(SnackBar(content: Text('Kuota ditambah $amount sesi.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  /// Simpan ke server. Mengembalikan pesan error, atau null bila sukses.
  Future<String?> _save({
    required String description,
    int? calories,
    int? protein,
  }) async {
    try {
      final goal = await _repo.saveGoal(
        widget.client.id,
        description: description,
        targetCalories: calories,
        targetProtein: protein,
      );
      if (!mounted) return null;
      setState(() {
        currentTarget = goal.description;
        customCalories = goal.targetCalories;
        customProtein = goal.targetProtein;
      });
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }

  void _editTargetDialog() {
    final controller = TextEditingController(text: currentTarget);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tetapkan Target Program Klien'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Target Terukur'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = controller.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              if (text.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Target tidak boleh kosong.')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              final error = await _save(
                description: text,
                calories: customCalories,
                protein: customProtein,
              );
              messenger.showSnackBar(
                SnackBar(content: Text(error ?? 'Target program berhasil diperbarui!')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editNutritionDialog() {
    final calController = TextEditingController(text: customCalories?.toString() ?? '');
    final proController = TextEditingController(text: customProtein?.toString() ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sesuaikan Target Kalori & Protein'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Kalori (kkal)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: proController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Protein (g)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final cal = int.tryParse(calController.text.trim());
              final pro = int.tryParse(proController.text.trim());
              if (cal == null || pro == null) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Isi kalori dan protein dengan angka.')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              final error = await _save(
                description: currentTarget.isEmpty ? 'Program latihan' : currentTarget,
                calories: cal,
                protein: pro,
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Rekomendasi nutrisi klien berhasil disesuaikan!'),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Profil Klien: ${widget.client.name}',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(goalTypeOf(widget.client.goalType).icon, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paket tujuan klien',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          goalTypeOf(widget.client.goalType).label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.client.customGoal.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tujuan lain dari klien', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(widget.client.customGoal, style: const TextStyle(fontSize: 14, height: 1.3)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_pkg != null) ...[
              SessionQuotaCard(pkg: _pkg!, title: 'Kuota sesi klien'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scheduleSession,
                      icon: const Icon(Icons.event, size: 16),
                      label: const Text('Jadwalkan Sesi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addQuota,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Kuota'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _section(
              title: 'Target Program Klien',
              onEdit: _editTargetDialog,
              child: Text(
                currentTarget.isEmpty ? 'Belum ada target. Ketuk ikon pensil untuk menetapkan.' : currentTarget,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Target Nutrisi Harian (Kustom PT)',
              onEdit: _editNutritionDialog,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kalori: ${customCalories ?? '-'} kkal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Protein: ${customProtein ?? '-'} gram',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PtClientWorkoutScreen(
                        clientId: widget.client.id,
                        clientName: widget.client.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fitness_center, size: 18),
                label: Text('Kelola Program Latihan ${widget.client.name.split(' ').first}'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PtClientNutritionScreen(
                        clientId: widget.client.id,
                        clientName: widget.client.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: Text('Kelola Menu & Nutrisi ${widget.client.name.split(' ').first}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
