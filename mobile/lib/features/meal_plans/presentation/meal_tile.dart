import 'package:flutter/material.dart';

import '../domain/meal_plan.dart';

/// Kartu satu waktu makan. Dipakai di layar member (baca saja) dan layar PT
/// (dengan tombol ubah/hapus lewat [onEdit] / [onDelete]).
class MealTile extends StatelessWidget {
  final MealItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MealTile({super.key, required this.item, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  tooltip: 'Ubah',
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  tooltip: 'Hapus',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${item.protein} g protein',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${item.calories} kkal',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ringkasan total kalori/protein hari ini dibanding target PT (bila ada).
class MealSummary extends StatelessWidget {
  final MealPlan plan;
  const MealSummary({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final target = plan.target;
    final calTarget = target?.calories;
    final proTarget = target?.protein;

    Widget stat(String label, int value, int? goal, String unit) {
      final ratio = (goal == null || goal == 0) ? null : (value / goal).clamp(0.0, 1.0).toDouble();
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              goal == null ? '$value $unit' : '$value / $goal $unit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (ratio != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (target != null && target.description.isNotEmpty) ...[
            Text(
              target.description,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              stat('Kalori', plan.totalCalories, calTarget, 'kkal'),
              const SizedBox(width: 20),
              stat('Protein', plan.totalProtein, proTarget, 'g'),
            ],
          ),
        ],
      ),
    );
  }
}
