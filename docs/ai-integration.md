# Integrasi AI

Status tahap 1: layanan AI **berjalan dengan hasil contoh** dan **belum dipanggil** oleh backend maupun aplikasi.

## Rencana integrasi
1. Backend membuat modul `nutrition-scan`, `meal-plans`, `grocery-recommendations`, `ai-chatbot` yang meneruskan permintaan ke `AI_SERVICE_URL`.
2. Aplikasi hanya berbicara dengan backend (satu pintu, token sama).
3. Hasil scan disimpan ke `nutrition-history`.

## Memasang model deteksi makanan asli
1. Latih/siapkan model dan daftar kelas (`ai-service/models/class_labels.json`).
2. Implementasikan `load_real_model()` di `ai-service/app/food_detection/model_loader.py`.
3. Pastikan setiap kelas ada di `data/nutrition_food_dictionary.json`.

Data gizi dan harga di `ai-service/data/` hanya perkiraan untuk demo.
