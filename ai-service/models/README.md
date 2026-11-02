# Folder model AI

`class_labels.json` berisi daftar kelas makanan (harus sesuai urutan output model).
Taruh file model asli di sini (mis. `food_model.h5`, tidak ikut git), lalu implementasikan
`load_real_model()` di `app/food_detection/model_loader.py`.
Selama belum, layanan memakai StubModel dan setiap respons ditandai `is_stub: true`.
