import { Link } from 'react-router-dom';
import { useAuth } from '../../auth';
import { ErrorBox, Loading, PageHead } from '../../components/ui';
import { rupiah } from '../../format';
import { useFetch } from '../../hooks';
import type { Dashboard } from '../../types';

export default function DashboardPage() {
  const { user } = useAuth();
  const { data: d, loading, error, reload } = useFetch<Dashboard>('/admin/dashboard');
  if (loading) return <Loading />;
  if (error || !d) return <ErrorBox message={error ?? 'Data kosong'} onRetry={reload} />;

  const stats = [
    { icon: '👥', label: 'Member aktif', value: d.activeMembers.toLocaleString('id-ID'), sub: 'membership berlaku' },
    { icon: '🏋️', label: 'Personal Trainer', value: d.trainers.toLocaleString('id-ID'), sub: 'PT aktif' },
    { icon: '📅', label: 'Sesi minggu ini', value: d.sessionsThisWeek.toLocaleString('id-ID'), sub: 'diterima & selesai' },
    { icon: '💰', label: 'Pendapatan membership', value: rupiah(d.revenueThisMonth), sub: `bulan ini · total ${rupiah(d.revenueTotal)}` },
  ];
  const todo = [
    { done: d.checklist.hasPlans, text: 'Buat paket harga', to: '/admin/cabang?tab=paket' },
    { done: d.checklist.hasPhotos, text: 'Unggah foto fasilitas', to: '/admin/cabang?tab=foto' },
    { done: d.checklist.hasTrainers, text: 'Tambahkan Personal Trainer', to: '/admin/trainer' },
  ];

  return (
    <>
      <PageHead title={`Halo, ${user?.name.split(' ')[0]} 👋`} sub={`Ringkasan ${d.gymName}`} />
      <div className="stat-grid">
        {stats.map((s) => (
          <div className="stat" key={s.label}>
            <span className="stat-icon">{s.icon}</span>
            <small>{s.label}</small>
            <strong>{s.value}</strong>
            <span className="muted">{s.sub}</span>
          </div>
        ))}
      </div>

      {d.pendingBookings > 0 && (
        <Link to="/admin/booking" className="notice">
          🔔 Ada <b>{d.pendingBookings}</b> permintaan booking menunggu respons PT. Lihat →
        </Link>
      )}

      {todo.some((t) => !t.done) && (
        <div className="card">
          <h3>Lengkapi cabang Anda</h3>
          <p className="muted">Agar tampil menarik dan bisa dipakai member di aplikasi.</p>
          <ul className="todo">
            {todo.map((t) => (
              <li key={t.text} className={t.done ? 'done' : ''}>
                <span>{t.done ? '✅' : '⬜'}</span>
                {t.done ? t.text : <Link to={t.to}>{t.text}</Link>}
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}
