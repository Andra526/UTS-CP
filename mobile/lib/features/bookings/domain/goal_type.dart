import 'package:flutter/material.dart';

/// Paket tujuan latihan yang dipilih member saat booking PT.
/// `value` harus sama dengan nilai di backend (GOAL_TYPES).
class GoalType {
  final String value;
  final String label;
  final IconData icon;

  const GoalType(this.value, this.label, this.icon);
}

const List<GoalType> goalTypes = [
  GoalType('WEIGHT_LOSS', 'Turun Berat Badan', Icons.trending_down),
  GoalType('MUSCLE_GAIN', 'Naik Massa Otot', Icons.fitness_center),
  GoalType('TONING', 'Bentuk Tubuh (Toning)', Icons.accessibility_new),
  GoalType('ENDURANCE', 'Stamina & Daya Tahan', Icons.directions_run),
  GoalType('REHAB', 'Pemulihan Cedera', Icons.healing_outlined),
  GoalType('GENERAL', 'Kebugaran Umum', Icons.favorite_border),
];

GoalType goalTypeOf(String value) {
  for (final g in goalTypes) {
    if (g.value == value) return g;
  }
  return goalTypes.last;
}
