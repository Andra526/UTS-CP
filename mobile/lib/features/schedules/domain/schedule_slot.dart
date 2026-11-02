import '../../../shared/helpers/json_utils.dart';

class ScheduleSlot {
  final String id;
  final String day;
  final String startTime;
  final String endTime;

  const ScheduleSlot({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
    id: asString(json['id']),
    day: asString(json['day']),
    startTime: asString(json['startTime']),
    endTime: asString(json['endTime']),
  );

  String get timeLabel => '$startTime - $endTime WIB';
}
