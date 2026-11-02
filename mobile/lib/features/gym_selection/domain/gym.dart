import 'package:flutter/material.dart';

import '../../../shared/helpers/json_utils.dart';

IconData facilityIcon(String name) {
  switch (name) {
    case 'fitness_center':
      return Icons.fitness_center;
    case 'directions_run':
      return Icons.directions_run;
    case 'lock_outline':
      return Icons.lock_outline;
    case 'shower_outlined':
      return Icons.shower_outlined;
    case 'wifi':
      return Icons.wifi;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'hot_tub_outlined':
      return Icons.hot_tub_outlined;
    case 'sports_gymnastics':
      return Icons.sports_gymnastics;
    default:
      return Icons.check_circle_outline;
  }
}

class GymFacility {
  final String label;
  final IconData icon;

  const GymFacility({required this.label, required this.icon});

  factory GymFacility.fromJson(Map<String, dynamic> json) => GymFacility(
    label: asString(json['label']),
    icon: facilityIcon(asString(json['icon'])),
  );
}

class GymPlan {
  final String id;
  final String name;
  final int price;
  final int durationDays;
  final String note;
  final bool isPopular;

  const GymPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.note,
    required this.isPopular,
  });

  factory GymPlan.fromJson(Map<String, dynamic> json) => GymPlan(
    id: asString(json['id']),
    name: asString(json['name']),
    price: asInt(json['price']),
    durationDays: asInt(json['durationDays']),
    note: asString(json['note']),
    isPopular: asBool(json['isPopular']),
  );

  /// Label periode untuk kartu paket, mis. "/bulan".
  String get periodLabel {
    if (durationDays >= 365) return '/tahun';
    if (durationDays >= 28) return '/bulan';
    return '/hari';
  }
}

class Gym {
  final String id;
  final String name;
  final String city;
  final String address;
  final String openHours;
  final String phone;
  final String imageUrl;
  final double rating;
  final int memberCount;
  final int trainerCount;
  final List<GymFacility> facilities;
  final List<GymPlan> plans;
  /// Foto fasilitas yang diunggah admin gym lewat website.
  final List<String> images;

  const Gym({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.openHours,
    required this.phone,
    required this.imageUrl,
    required this.rating,
    required this.memberCount,
    required this.trainerCount,
    required this.facilities,
    required this.plans,
    this.images = const [],
  });

  factory Gym.fromJson(Map<String, dynamic> json) => Gym(
    id: asString(json['id']),
    name: asString(json['name']),
    city: asString(json['city']),
    address: asString(json['address']),
    openHours: asString(json['openHours']),
    phone: asString(json['phone']),
    imageUrl: asString(json['imageUrl']),
    rating: asDouble(json['rating']),
    memberCount: asInt(json['memberCount']),
    trainerCount: asInt(json['trainerCount']),
    facilities: asList(json['facilities'])
        .map((e) => GymFacility.fromJson(asMap(e)))
        .toList(),
    plans: asList(json['plans']).map((e) => GymPlan.fromJson(asMap(e))).toList(),
    images: asList(json['images'])
        .map((e) => asString(asMap(e)['url']))
        .where((u) => u.isNotEmpty)
        .toList(),
  );
}
