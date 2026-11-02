import 'package:flutter/material.dart';

import '../domain/goal_type.dart';

/// Label kecil paket tujuan (mis. "Turun Berat Badan") di kartu booking/klien.
class GoalChip extends StatelessWidget {
  final String goalType;
  const GoalChip({super.key, required this.goalType});

  @override
  Widget build(BuildContext context) {
    final g = goalTypeOf(goalType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(g.icon, size: 12, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            g.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
