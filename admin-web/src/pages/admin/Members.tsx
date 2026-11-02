import { useState, type FormEvent } from 'react';
import toast from 'react-hot-toast';
import { api } from '../../api';
import { Badge, Confirm, Empty, ErrorBox, Field, Loading, Modal, PageHead } from '../../components/ui';
import { dateID, rupiah } from '../../format';
import { useFetch, withToast } from '../../hooks';
import type { Gym, Membership } from '../../types';

export default function Members() {
  const { data, loading, error, reload } = useFetch<Membership[]>('/admin/memberships');
  const plans = useFetch<Gym>('/admin/gym');
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<'ALL' | 'ACTIVE' | 'EXPIRED'>('ALL');
  const [add, setAdd] = useState<{ name: string; email: string; phone: string; planId: string } | null>(null);
  const [del, setDel] = useState<Membership | null>(null);

  if (loading) return <Loading />;
  if (error || !data) return <ErrorBox message={error ?? 'Data kosong'} onRetry={reload} />;

  const rows = data.filter((m) =>
    (status === 'ALL' || m.status === status) &&
    (`${m.user.name} ${m.user.email}`.toLowerCase().includes(q.toLowerCase())));

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!add) return;
    const res = await withToast(
      api.post<{ temporaryPassword?: string }>('/admin/memberships', { ...add, phone: add.phone || undefined }),
      { loading: 'Mendaftarkan member…', success: 'Membership dibuat' },
    );
    if (res) {
      setAdd(null);
      reload();
      if (res.temporaryPassword) {
        toast(`Akun baru dibuat. Password sementara: ${res.temporaryPassword} (catat & berikan ke member)`, { icon: '🔑', duration: 15000 });
      }
    }
  };

  const setMembership = async (m: Membership, patch: Record<string, string>, ok: string) => {
    if (await withToast(api.patch(`/admin/memberships/${m.id}`, patch), { loading: 'Memperbarui…', success: ok })) reload();
  };

  const planList = plans.data?.plans ?? [];

  return (
    <>
      <PageHead title="Member & Membership" sub="Member yang membeli paket di aplikasi otomatis muncul di sini."
        action={<button className="btn btn-dark" onClick={() => planList.length ? setAdd({ name: '', email: '', phone: '', planId: planList[0].id }) : toast.error('Buat paket harga dulu di Kelola Cabang')}>+ Daftarkan member</button>} />
      <div className="toolbar">
        <input className="search" placeholder="Cari nama atau email…" value={q} onChange={(e) => setQ(e.target.value)} />
        <div className="seg">
          {(['ALL', 'ACTIVE', 'EXPIRED'] as const).map((s) => (
            <button key={s} className={status === s ? 'active' : ''} onClick={() => setStatus(s)}>{s === 'ALL' ? 'Semua' : s === 'ACTIVE' ? 'Aktif' : 'Berakhir'}</button>
          ))}
        </div>
      </div>
      {rows.length === 0 ? <div className="card"><Empty icon="👥" title="Tidak ada member" text="Belum ada data yang cocok." /></div> : (
        <div className="card table-wrap">
          <table>
            <thead><tr><th>Member</th><th>Paket</th><th>Periode</th><th>Dibayar</th><th>Status</th><th /></tr></thead>
            <tbody>
              {rows.map((m) => (
                <tr key={m.id}>
                  <td><strong>{m.user.name}</strong><br /><small className="muted">{m.user.email}</small></td>
                  <td>{m.plan.name}</td>
                  <td>{dateID(m.startDate)} – {dateID(m.endDate)}</td>
                  <td>{rupiah(m.price)}</td>
                  <td>
                    {m.status === 'ACTIVE'
                      ? <Badge tone={m.daysLeft <= 7 ? 'amber' : 'green'}>Aktif · {m.daysLeft} hari</Badge>
                      : <Badge tone="gray">Berakhir</Badge>}
                  </td>
                  <td className="actions">
                    {m.status === 'ACTIVE'
                      ? <button className="btn btn-sm btn-ghost" onClick={() => void setMembership(m, { status: 'EXPIRED' }, 'Membership diakhiri')}>Akhiri</button>
                      : <button className="btn btn-sm btn-ghost" onClick={() => void setMembership(m, { status: 'ACTIVE', endDate: new Date(Date.now() + 30 * 86400000).toISOString() }, 'Diaktifkan 30 hari')}>Aktifkan 30 hr</button>}
                    <button className="btn btn-sm btn-ghost danger" onClick={() => setDel(m)}>Hapus</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {add && (
        <Modal title="Daftarkan member" onClose={() => setAdd(null)}>
          <form className="stack" onSubmit={submit}>
            <Field label="Nama"><input required autoFocus minLength={2} value={add.name} onChange={(e) => setAdd({ ...add, name: e.target.value })} /></Field>
            <div className="grid2">
              <Field label="Email"><input type="email" required value={add.email} onChange={(e) => setAdd({ ...add, email: e.target.value })} /></Field>
              <Field label="No. HP"><input value={add.phone} onChange={(e) => setAdd({ ...add, phone: e.target.value })} /></Field>
            </div>
            <Field label="Paket" hint="Jika email belum terdaftar, akun dibuat otomatis dengan password sementara.">
              <select value={add.planId} onChange={(e) => setAdd({ ...add, planId: e.target.value })}>
                {planList.map((p) => <option key={p.id} value={p.id}>{p.name} — {rupiah(p.price)} / {p.durationDays} hari</option>)}
              </select>
            </Field>
            <div className="modal-actions"><button type="button" className="btn btn-ghost" onClick={() => setAdd(null)}>Batal</button><button className="btn btn-dark">Daftarkan</button></div>
          </form>
        </Modal>
      )}
      {del && <Confirm title="Hapus membership?" message={`Membership ${del.user.name} (${del.plan.name}) akan dihapus dan tidak lagi dihitung di pendapatan.`} onClose={() => setDel(null)}
        onConfirm={async () => { if (await withToast(api.del(`/admin/memberships/${del.id}`), { loading: 'Menghapus…', success: 'Membership dihapus' })) reload(); }} />}
    </>
  );
}
