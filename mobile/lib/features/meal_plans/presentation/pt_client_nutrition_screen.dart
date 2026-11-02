import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/async_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/meal_plan_repository.dart';
import '../domain/meal_plan.dart';
import 'meal_tile.dart';

/// Menu & nutrisi SATU klien (khusus klien yang dipilih di daftar klien PT).
/// PT dapat menambah, mengubah, dan menghapus menu; member yang bersangkutan
/// langsung melihat perubahannya di layar "Pola Makan Saya".
class PtClientNutritionScreen extends StatelessWidget {
  final String clientId;
  final String clientName;
  const PtClientNutritionScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  static const _categories = [
    'Sarapan',
    'Snack Pagi',
    'Makan Siang',
    'Snack Sore',
    'Makan Malam',
    'Snack Malam',
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
    MealPlanRepository repo,
    VoidCallback reload, {
    MealItem? item,
  }) async {
    final result = await showDialog<_MealFormResult>(
      context: context,
      builder: (_) => _MealFormDialog(item: item, categories: _categories),
    );
    if (result == null || !context.mounted) return;
    if (item == null) {
      await _run(
        context,
        () => repo.add(
          clientId,
          time: result.time,
          category: result.category,
          description: result.description,
          calories: result.calories,
          protein: result.protein,
        ),
        'Menu ditambahkan. Klien langsung melihatnya.',
        reload,
      );
    } else {
      await _run(
        context,
        () => repo.update(
          item.id,
          time: result.time,
          category: result.category,
          description: result.description,
          calories: result.calories,
          protein: result.protein,
        ),
        'Menu diperbarui. Perubahan sudah tampil di akun klien.',
        reload,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MealPlanRepository repo,
    MealItem item,
    VoidCallback reload,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus menu?'),
        content: Text('"${item.category}" akan dihapus dari pola makan $clientName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () => repo.remove(item.id), 'Menu dihapus.', reload);
  }

  @override
  Widget build(BuildContext context) {
    final repo = MealPlanRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Menu & Nutrisi: $clientName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: AsyncBuilder<MealPlan>(
        loader: () => repo.forClient(clientId),
        builder: (context, plan, reload) {
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
                          icon: Icons.restaurant_menu,
                          title: 'Belum ada menu untuk $clientName',
                          subtitle:
                              'Ketuk "Tambah Menu" untuk menyusun pola makan klien ini.',
                        ),
                      )
                    else ...[
                      MealSummary(plan: plan),
                      const SizedBox(height: 16),
                      for (final item in plan.items)
                        MealTile(
                          item: item,
                          onEdit: () => _openForm(context, repo, reload, item: item),
                          onDelete: () => _confirmDelete(context, repo, item, reload),
                        ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  heroTag: 'add-meal',
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  onPressed: () => _openForm(context, repo, reload),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Menu'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MealFormResult {
  final String time;
  final String category;
  final String description;
  final int calories;
  final int protein;
  const _MealFormResult(this.time, this.category, this.description, this.calories, this.protein);
}

class _MealFormDialog extends StatefulWidget {
  final MealItem? item;
  final List<String> categories;
  const _MealFormDialog({required this.item, required this.categories});

  @override
  State<_MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends State<_MealFormDialog> {
  late final TextEditingController _desc;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _category;
  late String _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _desc = TextEditingController(text: i?.description ?? '');
    _kcal = TextEditingController(text: i == null ? '' : '${i.calories}');
    _protein = TextEditingController(text: i == null ? '' : '${i.protein}');
    _category = TextEditingController(text: i?.category ?? widget.categories.first);
    _time = i?.time ?? '07:30';
  }

  @override
  void dispose() {
    _desc.dispose();
    _kcal.dispose();
    _protein.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  void _submit() {
    final desc = _desc.text.trim();
    final category = _category.text.trim();
    final kcal = int.tryParse(_kcal.text.trim());
    final protein = int.tryParse(_protein.text.trim());
    if (category.length < 2 || desc.length < 2) {
      setState(() => _error = 'Isi kategori dan deskripsi makanan.');
      return;
    }
    if (kcal == null || protein == null || kcal < 0 || protein < 0) {
      setState(() => _error = 'Kalori dan protein harus berupa angka.');
      return;
    }
    Navigator.pop(context, _MealFormResult(_time, category, desc, kcal, protein));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Menu' : 'Ubah Menu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _category,
                    decoration: const InputDecoration(labelText: 'Waktu makan'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_time),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final c in widget.categories)
                  ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _category.text = c),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi makanan'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kcal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kalori (kkal)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _protein,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                  ),
                ),
              ],
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
