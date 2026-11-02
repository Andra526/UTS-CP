import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class BookingStatusChip extends StatelessWidget {
  final String status;
  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    switch (status) {
      case BookingStatus.accepted:
        fg = Colors.blue;
        bg = const Color(0xFFE3F2FD);
        break;
      case BookingStatus.completed:
        fg = Colors.green;
        bg = Colors.green.shade50;
        break;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        fg = Colors.red;
        bg = Colors.red.shade50;
        break;
      default:
        fg = Colors.orange.shade800;
        bg = Colors.orange.shade50;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        BookingStatus.label(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
