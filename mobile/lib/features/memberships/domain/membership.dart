import '../../../shared/helpers/json_utils.dart';

class Membership {
  final String id;
  final String gymId;
  final String gymName;
  final String planName;
  final int price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int remainingSeconds;

  const Membership({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.remainingSeconds,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    final gym = asMap(json['gym']);
    final plan = asMap(json['plan']);
    return Membership(
      id: asString(json['id']),
      gymId: asString(json['gymId']),
      gymName: asString(gym['name']),
      planName: asString(plan['name']),
      price: asInt(json['price']),
      startDate: asDate(json['startDate']),
      endDate: asDate(json['endDate']),
      status: asString(json['status']),
      remainingSeconds: asInt(json['remainingSeconds']),
    );
  }
}
