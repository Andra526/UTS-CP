# Rilis ke Play Store (ringkas)

1. Ganti `applicationId`, nama, dan ikon aplikasi.
2. Buat keystore dan atur `key.properties`.
3. Build: `flutter build appbundle --dart-define=API_BASE_URL=https://api.domain-anda.com`.
4. Unggah `.aab` di Play Console, isi kebijakan privasi dan data safety.
5. Pastikan backend sudah HTTPS dan memakai database produksi.
