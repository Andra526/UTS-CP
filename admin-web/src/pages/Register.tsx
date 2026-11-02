import { useEffect, useMemo, useState, type ChangeEvent, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { api } from '../api';
import { useAuth } from '../auth';
import { Field, Logo } from '../components/ui';
import { withToast } from '../hooks';
import type { Gym, User } from '../types';

const MAX_FILES = 6;
const MAX_MB = 3;

export default function Register() {
  const { adopt } = useAuth();
  const nav = useNavigate();
  const [busy, setBusy] = useState(false);
  const [f, setF] = useState({
    ownerName: '', birthPlace: '', birthDate: '', email: '', phone: '', password: '', confirm: '',
    gymName: '', city: '', address: '', openHours: '06.00 - 22.00',
  });
  const [files, setFiles] = useState<File[]>([]);
  const previews = useMemo(() => files.map((x) => URL.createObjectURL(x)), [files]);
  useEffect(() => () => previews.forEach(URL.revokeObjectURL), [previews]);

  const set = (k: keyof typeof f) => (e: ChangeEvent<HTMLInputElement>) => setF({ ...f, [k]: e.target.value });

  const pick = (e: ChangeEvent<HTMLInputElement>) => {
    const chosen = Array.from(e.target.files ?? []);
    e.target.value = '';
    const ok: File[] = [];
    for (const x of chosen) {
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(x.type)) {
        toast.error(`${x.name}: harus JPG, PNG, atau WEBP`);
      } else if (x.size > MAX_MB * 1024 * 1024) {
        toast.error(`${x.name}: lebih dari ${MAX_MB} MB`);
      } else ok.push(x);
    }
    const merged = [...files, ...ok];
    if (merged.length > MAX_FILES) toast(`Maksimal ${MAX_FILES} foto`, { icon: '📷' });
    setFiles(merged.slice(0, MAX_FILES));
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (f.password !== f.confirm) return void toast.error('Konfirmasi password tidak sama');
    if (new Date(f.birthDate) > new Date()) return void toast.error('Tanggal lahir tidak valid');

    const fd = new FormData();
    (['ownerName', 'birthPlace', 'birthDate', 'email', 'phone', 'password', 'gymName', 'city', 'address', 'openHours'] as const)
      .forEach((k) => f[k] && fd.append(k, f[k]));
    files.forEach((x) => fd.append('images', x));

    setBusy(true);
    const res = await withToast(
      api.post<{ accessToken: string; user: User; gym: Gym }>('/gym-applications', fd),
      { loading: 'Mendaftarkan gym Anda…', success: 'Gym berhasil didaftarkan! 🎉' },
    );
    setBusy(false);
    if (res) {
      adopt(res);
      toast('Cabang Anda sudah tampil di aplikasi GymFit. Lengkapi paket harga agar member bisa berlangganan.', {
        icon: '📱', duration: 6000,
      });
      nav('/admin');
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-side">
        <Link to="/"><Logo light /></Link>
        <h2>Daftarkan gym Anda, tampil di HP member hari ini juga.</h2>
        <ul className="ticks">
          <li>Tanpa antre persetujuan — langsung aktif</li>
          <li>Akun admin dibuat otomatis untuk cabang ini</li>
          <li>Tambah PT, paket harga, dan foto kapan saja</li>
        </ul>
      </div>
      <form className="auth-card wide" onSubmit={submit}>
        <h1>Daftarkan Gym</h1>
        <p className="muted">Satu pendaftaran = satu cabang. Untuk cabang lain, daftar lagi dengan email berbeda.</p>

        <h4 className="form-section">Data pemilik</h4>
        <Field label="Nama lengkap"><input required minLength={2} value={f.ownerName} onChange={set('ownerName')} placeholder="Rina Pemilik" /></Field>
        <div className="grid2">
          <Field label="Tempat lahir"><input required minLength={2} value={f.birthPlace} onChange={set('birthPlace')} placeholder="Surabaya" /></Field>
          <Field label="Tanggal lahir"><input type="date" required value={f.birthDate} onChange={set('birthDate')} max={new Date().toISOString().slice(0, 10)} /></Field>
        </div>
        <div className="grid2">
          <Field label="Email (untuk login)"><input type="email" required value={f.email} onChange={set('email')} placeholder="rina@gymku.com" /></Field>
          <Field label="No. HP"><input value={f.phone} onChange={set('phone')} placeholder="0812xxxxxxx" /></Field>
        </div>
        <div className="grid2">
          <Field label="Password" hint="Minimal 6 karakter"><input type="password" required minLength={6} value={f.password} onChange={set('password')} /></Field>
          <Field label="Ulangi password"><input type="password" required value={f.confirm} onChange={set('confirm')} /></Field>
        </div>

        <h4 className="form-section">Data gym</h4>
        <Field label="Nama gym" hint="Contoh: Iron Temple Surabaya"><input required minLength={3} value={f.gymName} onChange={set('gymName')} /></Field>
        <div className="grid2">
          <Field label="Kota"><input required minLength={2} value={f.city} onChange={set('city')} placeholder="Surabaya" /></Field>
          <Field label="Jam buka"><input value={f.openHours} onChange={set('openHours')} /></Field>
        </div>
        <Field label="Lokasi / alamat lengkap"><input required minLength={5} value={f.address} onChange={set('address')} placeholder="Jl. Raya Darmo No. 10" /></Field>

        <Field label="Gambar fasilitas" hint={`JPG/PNG/WEBP, maks ${MAX_MB} MB, sampai ${MAX_FILES} foto. Foto pertama jadi sampul di aplikasi.`}>
          <label className="dropzone">
            <input type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={pick} hidden />
            <span>📷 Pilih foto fasilitas</span>
          </label>
        </Field>
        {previews.length > 0 && (
          <div className="thumbs">
            {previews.map((src, i) => (
              <div className="thumb" key={src}>
                <img src={src} alt={`Foto ${i + 1}`} />
                {i === 0 && <span className="cover-tag">Sampul</span>}
                <button type="button" aria-label="Hapus foto" onClick={() => setFiles(files.filter((_, j) => j !== i))}>✕</button>
              </div>
            ))}
          </div>
        )}

        <button className="btn btn-dark btn-block" disabled={busy}>{busy ? 'Mendaftarkan…' : 'Daftarkan Gym'}</button>
        <p className="muted center">Sudah punya akun? <Link to="/masuk">Masuk</Link></p>
      </form>
    </div>
  );
}
