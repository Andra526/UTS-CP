import 'package:flutter/material.dart';

import '../domain/workout_plan.dart';

/// Kartu satu gerakan. Member: tombol centang [onToggleDone].
/// PT: tombol ubah/hapus lewat [onEdit] / [onDelete].
class WorkoutTile extends StatelessWidget {
  final WorkoutItem item;
  final VoidCallback? onToggleDone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkoutTile({
    super.key,
    required this.item,
    this.onToggleDone,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = item.doneToday;
    final detail = StringBuffer('${item.sets} set × ${item.reps}');
    if (item.restSec != null && item.restSec! > 0) {
      detail.write(' • istirahat ${item.restSec} dtk');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.exercise,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(detail.toString(), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          if (onToggleDone != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: done ? 'Batalkan' : 'Tandai selesai',
              icon: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? Colors.green : Colors.grey,
              ),
              onPressed: onToggleDone,
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
    );
  }
}
