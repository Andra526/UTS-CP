import 'package:flutter/material.dart';

import '../../../core/errors/error_message.dart';
import '../../authentication/presentation/session_controller.dart';
import '../data/profile_repository.dart';

/// Dialog ubah nama (dan nomor HP). Mengembalikan true jika berhasil disimpan.
Future<bool> showEditProfileDialog(BuildContext context) async {
  final user = session.user;
  final name = TextEditingController(text: user?.name ?? '');
  final phone = TextEditingController(text: user?.phone ?? '');
  String? error;
  bool saving = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Ubah Data Pribadi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. HP'),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: saving
                ? null
                : () async {
                    final newName = name.text.trim();
                    if (newName.length < 2) {
                      setDialogState(() => error = 'Nama minimal 2 karakter.');
                      return;
                    }
                    setDialogState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await ProfileRepository().updateMe(
                        name: newName,
                        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        error = errorMessage(e);
                      });
                    }
                  },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  phone.dispose();
  return result ?? false;
}
