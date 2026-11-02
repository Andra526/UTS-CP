import { useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuth } from '../auth';
import { Field, Logo } from '../components/ui';
import { withToast } from '../hooks';

export default function Login() {
  const { user, login } = useAuth();
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);

  if (user) return <Navigate to="/admin" replace />;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const ok = await withToast(login(email, password).then(() => true), {
      loading: 'Memeriksa akun…',
      success: 'Selamat datang kembali! 💪',
    });
    setBusy(false);
    if (ok) nav('/admin');
  };

  return (
    <div className="auth-page">
      <div className="auth-side">
        <Link to="/"><Logo light /></Link>
        <h2>Kelola gym Anda dari satu tempat.</h2>
        <p>Member, personal trainer, jadwal, dan pendapatan — semuanya langsung tersinkron dengan aplikasi GymFit di HP member Anda.</p>
      </div>
      <form className="auth-card" onSubmit={submit}>
        <h1>Masuk Admin Gym</h1>
        <p className="muted">Gunakan email yang Anda daftarkan saat membuat cabang.</p>
        <Field label="Email">
          <input type="email" required autoFocus value={email} onChange={(e) => setEmail(e.target.value)} placeholder="nama@email.com" />
        </Field>
        <Field label="Password">
          <input type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />
        </Field>
        <button className="btn btn-dark btn-block" disabled={busy}>{busy ? 'Masuk…' : 'Masuk'}</button>
        <p className="muted center">
          Belum punya gym di GymFit? <Link to="/daftar">Daftarkan gym</Link>
        </p>
        <button type="button" className="link-btn" onClick={() => toast('Hubungi pengelola sistem untuk reset password.', { icon: 'ℹ️' })}>
          Lupa password?
        </button>
      </form>
    </div>
  );
}
