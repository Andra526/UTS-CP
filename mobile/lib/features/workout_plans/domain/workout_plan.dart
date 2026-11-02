import '../../../shared/helpers/json_utils.dart';

class WorkoutItem {
  final String id;
  final String dayLabel;
  final String exercise;
  final int sets;
  final String reps;
  final int? restSec;
  final String note;
  final String trainerName;
  final bool doneToday;

  const WorkoutItem({
    required this.id,
    required this.dayLabel,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSec,
    required this.note,
    required this.trainerName,
    required this.doneToday,
  });

  factory WorkoutItem.fromJson(Map<String, dynamic> json) {
    final trainerUser = asMap(asMap(json['trainer'])['user']);
    return WorkoutItem(
      id: asString(json['id']),
      dayLabel: asString(json['dayLabel']),
      exercise: asString(json['exercise']),
      sets: asInt(json['sets'], 3),
      reps: asString(json['reps']),
      restSec: asIntOrNull(json['restSec']),
      note: asString(json['note']),
      trainerName: asString(trainerUser['name']),
      doneToday: asBool(json['doneToday']),
    );
  }
}

class WorkoutPlan {
  final String? clientName; // hanya terisi pada tampilan PT
  final List<WorkoutItem> items;

  const WorkoutPlan({required this.clientName, required this.items});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    clientName: asStringOrNull(asMap(json['client'])['name']),
    items: asList(json['items']).map((e) => WorkoutItem.fromJson(asMap(e))).toList(),
  );

  /// Kelompokkan gerakan per hari (urutan kemunculan dipertahankan).
  Map<String, List<WorkoutItem>> get byDay {
    final map = <String, List<WorkoutItem>>{};
    for (final i in items) {
      map.putIfAbsent(i.dayLabel, () => []).add(i);
    }
    return map;
  }
}
