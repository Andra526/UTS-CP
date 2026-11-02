import { Link } from 'react-router-dom';
import { useAuth } from '../auth';
import { Logo } from '../components/ui';

const FEATURES = [
  { icon: '📱', t: 'Langsung di aplikasi member', d: 'Begitu didaftarkan, cabang Anda muncul di aplikasi GymFit di HP — lengkap dengan foto, fasilitas, dan paket harga.' },
  { icon: '🏋️', t: 'Kelola Personal Trainer', d: 'Tambah, ubah, atau nonaktifkan PT. PT nonaktif otomatis hilang dari aplikasi tanpa menghapus riwayat sesinya.' },
  { icon: '👥', t: 'Member & membership', d: 'Pantau siapa yang aktif, siapa yang segera habis, dan daftarkan member baru langsung dari kasir.' },
  { icon: '💰', t: 'Pendapatan membership', d: 'Ringkasan pendapatan bulan ini dan total, tanpa perlu rekap manual di spreadsheet.' },
  { icon: '📅', t: 'Booking & sesi latihan', d: 'Lihat semua booking PT dan sesi yang sudah berjalan, termasuk kehadiran dan intensitas latihan.' },
  { icon: '🏢', t: 'Satu akun per cabang', d: 'Setiap cabang punya admin sendiri. Data antar-cabang terpisah dan tidak saling terlihat.' },
];

const STEPS = [
  { n: '01', t: 'Daftarkan gym', d: 'Isi data pemilik, nama & lokasi gym, serta foto fasilitas. Cukup 2 menit.' },
  { n: '02', t: 'Atur cabang', d: 'Tambahkan fasilitas, paket harga, dan Personal Trainer Anda.' },
  { n: '03', t: 'Member berdatangan', d: 'Cabang Anda tampil di aplikasi GymFit. Member memilih paket dan booking PT.' },
];

export default function Landing() {
  const { user } = useAuth();
  const cta = user ? { to: '/admin', label: 'Buka Dashboard' } : { to: '/daftar', label: 'Daftarkan Gym Gratis' };

  return (
    <div className="landing">
      <header className="topbar">
        <Link to="/"><Logo /></Link>
        <nav>
          <a href="#fitur">Fitur</a>
          <a href="#cara">Cara kerja</a>
          <Link to="/masuk" className="btn btn-ghost">Masuk</Link>
          <Link to={cta.to} className="btn btn-dark">{user ? 'Dashboard' : 'Daftar'}</Link>
        </nav>
      </header>

      <section className="hero">
        <div className="hero-copy">
          <span className="pill">Untuk pemilik gym & studio kebugaran</span>
          <h1>Gym Anda, <em>langsung</em> di genggaman member.</h1>
          <p>
            GymFit menghubungkan gym Anda dengan member lewat aplikasi mobile. Daftarkan cabang,
            kelola Personal Trainer, dan pantau membership — semua dari satu dashboard sederhana.
          </p>
          <div className="hero-cta">
            <Link to={cta.to} className="btn btn-lime btn-lg">{cta.label} →</Link>
            <Link to="/masuk" className="btn btn-outline btn-lg">Saya sudah punya akun</Link>
          </div>
          <div className="hero-stats">
            <div><strong>5 menit</strong><span>dari daftar sampai tampil</span></div>
            <div><strong>0 persetujuan</strong><span>langsung aktif</span></div>
            <div><strong>1 dashboard</strong><span>per cabang</span></div>
          </div>
        </div>

        <div className="hero-visual" aria-hidden>
          <div className="phone">
            <div className="phone-bar" />
            <div className="phone-card">
              <div className="phone-img" />
              <strong>Iron Temple Surabaya</strong>
              <small>📍 Surabaya · ⭐ 4.8 · 6 PT</small>
              <div className="chips"><span>🏋️ Free Weight</span><span>🚿 Shower</span><span>📶 Wi-Fi</span></div>
              <div className="phone-btn">Pilih Paket</div>
            </div>
            <div className="phone-card mini">
              <strong>Bulanan</strong>
              <small>Rp 250.000 /bulan</small>
            </div>
          </div>
          <div className="float-card f1">✅ Member baru bergabung</div>
          <div className="float-card f2">📈 Pendapatan bulan ini<br /><b>Rp 12.450.000</b></div>
        </div>
      </section>

      <section id="fitur" className="section">
        <h2>Semua yang dibutuhkan untuk mengelola gym</h2>
        <p className="muted section-sub">Sederhana, cepat, dan tidak perlu keahlian teknis.</p>
        <div className="feature-grid">
          {FEATURES.map((x) => (
            <article className="feature" key={x.t}>
              <div className="feature-icon">{x.icon}</div>
              <h3>{x.t}</h3>
              <p>{x.d}</p>
            </article>
          ))}
        </div>
      </section>

      <section id="cara" className="section dark">
        <h2>Cara kerjanya</h2>
        <div className="steps">
          {STEPS.map((s) => (
            <div className="step" key={s.n}>
              <span className="step-n">{s.n}</span>
              <h3>{s.t}</h3>
              <p>{s.d}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section cta-band">
        <h2>Siap membawa gym Anda ke aplikasi GymFit?</h2>
        <p className="muted">Pendaftaran gratis dan langsung aktif.</p>
        <Link to={cta.to} className="btn btn-dark btn-lg">{cta.label} →</Link>
      </section>

      <footer className="footer">
        <Logo />
        <span className="muted">© {new Date().getFullYear()} GymFit. Lebih Sehat, Lebih Kuat.</span>
      </footer>
    </div>
  );
}
