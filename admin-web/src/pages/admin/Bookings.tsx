import { useState } from 'react';
import { api } from '../../api';
import { Badge, Confirm, Empty, ErrorBox, Loading, PageHead } from '../../components/ui';
import { GOAL_LABELS, dateTimeID } from '../../format';
import { useFetch, withToast } from '../../hooks';
import type { Booking } from '../../types';

const STATUS: Record<Booking['status'], { label: string; tone: 'amber' | 'blue' | 'green' | 'red' | 'gray' }> = {
  PENDING: { label: 'Menunggu', tone: 'amber' },
  ACCEPTED: { label: 'Diterima', tone: 'blue' },
  COMPLETED: { label: 'Selesai', tone: 'green' },
  REJECTED: { label: 'Ditolak', tone: 'red' },
  CANCELLED: { label: 'Dibatalkan', tone: 'gray' },
};
const FILTERS = [
  { id: 'ALL', label: 'Semua' },
  { id: 'PENDING', label: 'Menunggu' },
  { id: 'ACCEPTED', label: 'Diterima' },
  { id: 'COMPLETED', label: 'Sesi selesai' },
  { id: 'CANCELLED', label: 'Batal/Tolak' },
] as const;

export default function Bookings() {
  const { data, loading, error, reload } = useFetch<Booking[]>('/admin/bookings');
  const [f, setF] = useState<(typeof FILTERS)[number]['id']>('ALL');
  const [cancel, setCancel] = useState<Booking | null>(null);
  const [del, setDel] = useState<Booking | null>(null);

  if (loading) return <Loading />;
  if (error || !data) return <ErrorBox message={error ?? 'Data kosong'} onRetry={reload} />;

  const rows = data.filter((b) => f === 'ALL' || b.status === f || (f === 'CANCELLED' && b.status === 'REJECTED'));

  return (
    <>
      <PageHead title="Booking & Sesi" sub="Permintaan booking PT dan laporan sesi latihan di cabang Anda." />
      <div className="toolbar">
        <div className="seg">
          {FILTERS.map((x) => <button key={x.id} className={f === x.id ? 'active' : ''} onClick={() => setF(x.id)}>{x.label}</button>)}
        </div>
      </div>
      {rows.length === 0 ? <div className="card"><Empty icon="📅" title="Belum ada booking" text="Booking dari member akan muncul di sini." /></div> : (
        <div className="card table-wrap">
          <table>
            <thead><tr><th>Waktu</th><th>Member</th><th>PT</th><th>Tujuan</th><th>Status</th><th>Laporan sesi</th><th /></tr></thead>
            <tbody>
              {rows.map((b) => (
                <tr key={b.id}>
                  <td>{dateTimeID(b.scheduledAt)}<br /><small className="muted">{b.durationMin} menit</small></td>
                  <td><strong>{b.client.name}</strong><br /><small className="muted">{b.client.email}</small></td>
                  <td>{b.trainer.user.name}</td>
                  <td><small>{GOAL_LABELS[b.goalType] ?? b.goalType}</small></td>
                  <td><Badge tone={STATUS[b.status].tone}>{STATUS[b.status].label}</Badge></td>
                  <td>{b.session ? <small>{b.session.attendance.replace('_', ' ')} · intensitas {b.session.intensity}/10{b.session.notes ? <><br />{b.session.notes}</> : null}</small> : <span className="muted">—</span>}</td>
                  <td className="actions">
                    {(b.status === 'PENDING' || b.status === 'ACCEPTED') && <button className="btn btn-sm btn-ghost" onClick={() => setCancel(b)}>Batalkan</button>}
                    <button className="btn btn-sm btn-ghost danger" onClick={() => setDel(b)}>Hapus</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {cancel && <Confirm title="Batalkan booking?" confirmLabel="Batalkan booking" message={`Booking ${cancel.client.name} dengan ${cancel.trainer.user.name} akan dibatalkan.`} onClose={() => setCancel(null)}
        onConfirm={async () => { if (await withToast(api.patch(`/admin/bookings/${cancel.id}`, { status: 'CANCELLED' }), { loading: 'Membatalkan…', success: 'Booking dibatalkan' })) reload(); }} />}
      {del && <Confirm title="Hapus data booking?" message="Booking beserta laporan sesinya akan dihapus permanen." onClose={() => setDel(null)}
        onConfirm={async () => { if (await withToast(api.del(`/admin/bookings/${del.id}`), { loading: 'Menghapus…', success: 'Booking dihapus' })) reload(); }} />}
    </>
  );
}
