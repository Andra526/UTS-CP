import { useState, type FormEvent } from 'react';
import { api } from '../../api';
import { Badge, Confirm, Empty, ErrorBox, Field, Loading, Modal, PageHead } from '../../components/ui';
import { useFetch, withToast } from '../../hooks';
import type { Trainer } from '../../types';

interface Form {
  id?: string;
  name: string; email: string; phone: string; password: string;
  specialization: string; experienceYears: number; bio: string;
}
const blank: Form = { name: '', email: '', phone: '', password: '', specialization: '', experienceYears: 0, bio: '' };

export default function Trainers() {
  const { data, loading, error, reload } = useFetch<Trainer[]>('/admin/trainers');
  const [edit, setEdit] = useState<Form | null>(null);
  const [del, setDel] = useState<Trainer | null>(null);
  const [off, setOff] = useState<Trainer | null>(null);

  if (loading) return <Loading />;
  if (error || !data) return <ErrorBox message={error ?? 'Data kosong'} onRetry={reload} />;

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!edit) return;
    const common = { name: edit.name, phone: edit.phone || undefined, specialization: edit.specialization, experienceYears: Number(edit.experienceYears), bio: edit.bio };
    const ok = edit.id
      ? await withToast(api.patch(`/admin/trainers/${edit.id}`, { ...common, ...(edit.password ? { password: edit.password } : {}) }), { loading: 'Menyimpan…', success: 'Data PT diperbarui' })
      : await withToast(api.post('/admin/trainers', { ...common, email: edit.email, password: edit.password }), { loading: 'Menambahkan PT…', success: 'PT ditambahkan — sudah bisa login di aplikasi' });
    if (ok) { setEdit(null); reload(); }
  };

  const toggle = async (t: Trainer, isActive: boolean) => {
    const ok = await withToast(api.patch(`/admin/trainers/${t.id}`, { isActive }), {
      loading: 'Memperbarui…',
      success: isActive ? `${t.user.name} diaktifkan kembali` : `${t.user.name} dinonaktifkan`,
    });
    if (ok) reload();
  };

  return (
    <>
      <PageHead title="Personal Trainer" sub="PT nonaktif tidak tampil dan tidak bisa dibooking di aplikasi."
        action={<button className="btn btn-dark" onClick={() => setEdit({ ...blank })}>+ Tambah PT</button>} />
      {data.length === 0 ? <div className="card"><Empty icon="🏋️" title="Belum ada Personal Trainer" text="Tambahkan PT pertama Anda agar member bisa booking sesi." /></div> : (
        <div className="card table-wrap">
          <table>
            <thead><tr><th>Nama</th><th>Spesialisasi</th><th>Pengalaman</th><th>Booking</th><th>Status</th><th /></tr></thead>
            <tbody>
              {data.map((t) => (
                <tr key={t.id} className={t.isActive ? '' : 'dim'}>
                  <td><strong>{t.user.name}</strong><br /><small className="muted">{t.user.email}</small></td>
                  <td>{t.specialization}</td>
                  <td>{t.experienceYears} th</td>
                  <td>{t._count.bookings}</td>
                  <td>{t.isActive ? <Badge tone="green">Aktif</Badge> : <Badge tone="gray">Nonaktif</Badge>}</td>
                  <td className="actions">
                    <button className="btn btn-sm btn-ghost" onClick={() => setEdit({ id: t.id, name: t.user.name, email: t.user.email, phone: t.user.phone ?? '', password: '', specialization: t.specialization, experienceYears: t.experienceYears, bio: t.bio })}>Ubah</button>
                    {t.isActive
                      ? <button className="btn btn-sm btn-ghost" onClick={() => setOff(t)}>Nonaktifkan</button>
                      : <button className="btn btn-sm btn-ghost" onClick={() => void toggle(t, true)}>Aktifkan</button>}
                    <button className="btn btn-sm btn-ghost danger" onClick={() => setDel(t)}>Hapus</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {edit && (
        <Modal title={edit.id ? 'Ubah Personal Trainer' : 'Tambah Personal Trainer'} onClose={() => setEdit(null)}>
          <form onSubmit={save} className="stack">
            <Field label="Nama"><input required autoFocus minLength={2} value={edit.name} onChange={(e) => setEdit({ ...edit, name: e.target.value })} /></Field>
            <div className="grid2">
              <Field label="Email (login di aplikasi)"><input type="email" required disabled={!!edit.id} value={edit.email} onChange={(e) => setEdit({ ...edit, email: e.target.value })} /></Field>
              <Field label="No. HP"><input value={edit.phone} onChange={(e) => setEdit({ ...edit, phone: e.target.value })} /></Field>
            </div>
            <Field label={edit.id ? 'Password baru (kosongkan jika tidak diubah)' : 'Password'}>
              <input type="password" minLength={6} required={!edit.id} value={edit.password} onChange={(e) => setEdit({ ...edit, password: e.target.value })} />
            </Field>
            <div className="grid2">
              <Field label="Spesialisasi"><input required minLength={2} value={edit.specialization} onChange={(e) => setEdit({ ...edit, specialization: e.target.value })} placeholder="Strength & Conditioning" /></Field>
              <Field label="Pengalaman (tahun)"><input type="number" min={0} value={edit.experienceYears} onChange={(e) => setEdit({ ...edit, experienceYears: Number(e.target.value) })} /></Field>
            </div>
            <Field label="Bio singkat"><input value={edit.bio} onChange={(e) => setEdit({ ...edit, bio: e.target.value })} /></Field>
            <div className="modal-actions"><button type="button" className="btn btn-ghost" onClick={() => setEdit(null)}>Batal</button><button className="btn btn-dark">Simpan</button></div>
          </form>
        </Modal>
      )}
      {off && <Confirm title="Nonaktifkan PT?" confirmLabel="Nonaktifkan" message={`${off.user.name} akan disembunyikan dari aplikasi dan tidak bisa dibooking. Riwayat sesi tetap tersimpan.`} onClose={() => setOff(null)} onConfirm={() => void toggle(off, false)} />}
      {del && <Confirm title="Hapus PT permanen?" message={`${del.user.name} dan akunnya akan dihapus. PT yang punya riwayat booking tidak bisa dihapus — nonaktifkan saja.`} onClose={() => setDel(null)}
        onConfirm={async () => { if (await withToast(api.del(`/admin/trainers/${del.id}`), { loading: 'Menghapus…', success: 'PT dihapus' })) reload(); }} />}
    </>
  );
}
