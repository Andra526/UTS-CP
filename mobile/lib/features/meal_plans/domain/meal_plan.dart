import '../../../shared/helpers/json_utils.dart';

class MealItem {
  final String id;
  final String time;
  final String category;
  final String description;
  final int calories;
  final int protein;
  final String trainerName;

  const MealItem({
    required this.id,
    required this.time,
    required this.category,
    required this.description,
    required this.calories,
    required this.protein,
    required this.trainerName,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    final trainer = asMap(json['trainer']);
    final trainerUser = asMap(trainer['user']);
    return MealItem(
      id: asString(json['id']),
      time: asString(json['time']),
      category: asString(json['category']),
      description: asString(json['description']),
      calories: asInt(json['calories']),
      protein: asInt(json['protein']),
      trainerName: asString(trainerUser['name']),
    );
  }
}

/// Target harian yang ditetapkan PT (boleh kosong).
class MealTarget {
  final String description;
  final int? calories;
  final int? protein;

  const MealTarget({required this.description, this.calories, this.protein});

  factory MealTarget.fromJson(Map<String, dynamic> json) => MealTarget(
    description: asString(json['description']),
    calories: asIntOrNull(json['calories']),
    protein: asIntOrNull(json['protein']),
  );
}

class MealPlan {
  final String? clientName; // hanya terisi pada tampilan PT
  final List<MealItem> items;
  final int totalCalories;
  final int totalProtein;
  final MealTarget? target;

  const MealPlan({
    required this.clientName,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.target,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final totals = asMap(json['totals']);
    return MealPlan(
      clientName: asStringOrNull(asMap(json['client'])['name']),
      items: asList(json['items']).map((e) => MealItem.fromJson(asMap(e))).toList(),
      totalCalories: asInt(totals['calories']),
      totalProtein: asInt(totals['protein']),
      target: json['target'] is Map ? MealTarget.fromJson(asMap(json['target'])) : null,
    );
  }
}
