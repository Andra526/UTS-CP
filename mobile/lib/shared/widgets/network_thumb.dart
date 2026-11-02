import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';

/// Foto unggahan admin disimpan server sebagai path relatif (/uploads/..);
/// tambahkan alamat server. Link penuh (http...) dipakai apa adanya.
String resolveImageUrl(String url) {
  if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
  return url;
}

/// Gambar dari internet dengan fallback ikon agar tidak error / blank
/// saat koneksi gagal atau URL tidak bisa dimuat.
class NetworkThumb extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final IconData fallbackIcon;

  const NetworkThumb({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 12,
    this.fallbackIcon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: Colors.grey.shade500),
    );
    if (url.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(width: width, height: height, child: fallback),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          resolveImageUrl(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(fallbackIcon, color: Colors.grey.shade500),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(color: Colors.grey.shade100);
          },
        ),
      ),
    );
  }
}
