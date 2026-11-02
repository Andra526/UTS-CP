import 'package:flutter/material.dart';

/// Tombol utama (hitam) atau outline, dengan status loading.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = loading ? null : onPressed;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    final Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? (color ?? Colors.black) : Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color ?? Colors.black,
                side: BorderSide(color: color ?? Colors.black),
                shape: shape,
              ),
              onPressed: action,
              child: content,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? const Color(0xFF111111),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
              ),
              onPressed: action,
              child: content,
            ),
    );
  }
}
