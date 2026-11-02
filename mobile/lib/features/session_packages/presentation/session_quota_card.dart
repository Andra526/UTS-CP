import 'package:flutter/material.dart';

import '../domain/session_package.dart';

/// Kartu "Sisa sesi: 5 dari 8" dengan bar progres.
/// [compact] = versi kecil untuk Beranda.
class SessionQuotaCard extends StatelessWidget {
  final SessionPackage pkg;
  final bool compact;
  final String? title;
  const SessionQuotaCard({super.key, required this.pkg, this.compact = false, this.title});

  @override
  Widget build(BuildContext context) {
    final exhausted = pkg.isExhausted;
    final color = exhausted ? Colors.red : Colors.black;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: exhausted ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'PT ${pkg.trainerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text(
                'Sisa sesi: ${pkg.remaining} dari ${pkg.total}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pkg.progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: exhausted ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exhausted
                ? 'Kuota habis. Minta PT menambah kuota untuk booking lagi.'
                : '${pkg.used} selesai'
                      '${pkg.reserved > 0 ? ' • ${pkg.reserved} terjadwal/menunggu' : ''}',
            style: TextStyle(
              color: exhausted ? Colors.red : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
