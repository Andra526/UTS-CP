import 'package:flutter/material.dart';

import '../../../shared/helpers/json_utils.dart';

class ActivityItem {
  final String id;
  final String type; // MEMBERSHIP | BOOKING | SESSION | WORKOUT
  final String title;
  final String subtitle;
  final DateTime at;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: asString(json['id']),
    type: asString(json['type']),
    title: asString(json['title']),
    subtitle: asString(json['subtitle']),
    at: asDate(json['at']),
  );

  IconData get icon {
    switch (type) {
      case 'MEMBERSHIP':
        return Icons.card_membership;
      case 'BOOKING':
        return Icons.event_note_outlined;
      case 'SESSION':
        return Icons.verified_outlined;
      case 'WORKOUT':
        return Icons.fitness_center;
      default:
        return Icons.history;
    }
  }

  Color get color {
    switch (type) {
      case 'MEMBERSHIP':
        return Colors.amber.shade800;
      case 'BOOKING':
        return Colors.orange;
      case 'SESSION':
        return Colors.green;
      case 'WORKOUT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class ActivityStats {
  final int sessionsCompleted;
  final int workoutsThisWeek;
  final int totalWorkouts;

  const ActivityStats({
    required this.sessionsCompleted,
    required this.workoutsThisWeek,
    required this.totalWorkouts,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) => ActivityStats(
    sessionsCompleted: asInt(json['sessionsCompleted']),
    workoutsThisWeek: asInt(json['workoutsThisWeek']),
    totalWorkouts: asInt(json['totalWorkouts']),
  );
}

class ActivityLog {
  final ActivityStats stats;
  final List<ActivityItem> items;

  const ActivityLog({required this.stats, required this.items});

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    stats: ActivityStats.fromJson(asMap(json['stats'])),
    items: asList(json['items']).map((e) => ActivityItem.fromJson(asMap(e))).toList(),
  );
}

/// "Baru saja", "5 menit lalu", "Hari ini 14:00", "Kemarin 09:30", "14 Okt 2026".
String formatActivityTime(DateTime at, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(at);
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(at.hour)}:${two(at.minute)}';

  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(at.year, at.month, at.day);
  final days = today.difference(day).inDays;
  if (days == 0) return 'Hari ini $clock';
  if (days == 1) return 'Kemarin $clock';
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${at.day} ${bulan[at.month - 1]} ${at.year}';
}
