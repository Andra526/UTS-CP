# Panduan setup

## Prasyarat
Node.js 20+, Python 3.10+, Flutter (sesuai `mobile/pubspec.yaml`).

## 1. Backend
```bash
cd backend
npm install
cp .env.example .env        # ganti JWT_SECRET
npm run setup               # prisma generate + db push + seed
npm run start:dev           # http://localhost:3000/health
npm test                    # 13 tes end-to-end
```
Akun demo (password `password123`): `andra.setya@email.com` (member), `alex.pt@gymfit.com` (PT), `admin@gymfit.com` (admin).

## 2. AI service (opsional)
```bash
cd ai-service
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
pytest
```

## 3. Mobile
```bash
cd mobile
flutter pub get
flutter analyze && flutter test
flutter run                                              # emulator Android
flutter run --dart-define=API_BASE_URL=http://IP-KOMPUTER:3000   # HP asli (satu Wi-Fi)
```
Android emulator memakai `10.0.2.2` untuk menjangkau komputer. Pada HP asli gunakan IP komputer.
