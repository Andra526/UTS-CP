# GymFit AI Service (FastAPI)

Layanan AI untuk fitur nutrisi. **Versi awal memakai hasil contoh (stub)**: semua respons
yang belum memakai model sungguhan memiliki `is_stub: true`.

```bash
cd ai-service
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000          # dokumentasi: http://localhost:8000/docs
pytest                                             # jalankan tes
```

| Endpoint | Fungsi | Status |
|---|---|---|
| POST /food/detect | foto makanan -> tebakan + gizi | stub (hasil deterministik dari isi gambar) |
| GET /food/dictionary | kamus gizi makanan | data contoh (perkiraan) |
| POST /grocery/recommendations | daftar belanja sesuai anggaran & target | algoritma greedy, harga contoh |
| POST /grocery/substitutions | bahan pengganti | berbasis aturan |
| POST /meal-plans/generate | menu harian 4x makan | template aturan |
| POST /chatbot/message | tanya jawab nutrisi | berbasis kata kunci |

Data gizi dan harga di `data/` adalah **perkiraan untuk demo**, bukan data resmi.
Cara memasang model asli: lihat `app/food_detection/model_loader.py`.
