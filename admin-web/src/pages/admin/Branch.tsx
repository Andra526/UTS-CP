import { useRef, useState, type FormEvent } from 'react';
import { useSearchParams } from 'react-router-dom';
import toast from 'react-hot-toast';
import { api, imgUrl } from '../../api';
import { Confirm, Empty, ErrorBox, Field, Loading, Modal, PageHead } from '../../components/ui';
import { FACILITY_ICONS, glyphOf, rupiah } from '../../format';
import { useFetch, withToast } from '../../hooks';
import type { Facility, Gym, Plan } from '../../types';

const TABS = [
  { id: 'info', label: 'Info' },
  { id: 'fasilitas', label: 'Fasilitas' },
  { id: 'paket', label: 'Paket Harga' },
  { id: 'foto', label: 'Foto' },
] as const;
type Tab = (typeof TABS)[number]['id'];

export default function Branch() {
  const { data: gym, setData, loading, error, reload } = useFetch<Gym>('/admin/gym');
  const [params, setParams] = useSearchParams();
  const tab = (TABS.find((t) => t.id === params.get('tab'))?.id ?? 'info') as Tab;

  if (loading) return <Loading />;
  if (error || !gym) return <ErrorBox message={error ?? 'Data kosong'} onRetry={reload} />;

  return (
    <>
      <PageHead title="Kelola Cabang" sub="Perubahan langsung terlihat di aplikasi member." />
      <div className="tabs" role="tablist">
        {TABS.map((t) => (
          <button key={t.id} role="tab" aria-selected={tab === t.id} className={tab === t.id ? 'active' : ''} onClick={() => setParams({ tab: t.id })}>
            {t.label}
          </button>
        ))}
      </div>
      {tab === 'info' && <InfoTab gym={gym} onSaved={setData} />}
      {tab === 'fasilitas' && <FacilitiesTab gym={gym} reload={reload} />}
      {tab === 'paket' && <PlansTab gym={gym} reload={reload} />}
      {tab === 'foto' && <PhotosTab gym={gym} onChange={setData} />}
    </>
  );
}

function InfoTab({ gym, onSaved }: { gym: Gym; onSaved: (g: Gym) => void }) {
  const [f, setF] = useState({ name: gym.name, city: gym.city, address: gym.address, openHours: gym.openHours, phone: gym.phone });
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement>) => setF({ ...f, [k]: e.target.value });
  const save = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    const res = await withToast(api.patch<Gym>('/admin/gym', f), { loading: 'Menyimpan…', success: 'Info cabang tersimpan' });
    setBusy(false);
    if (res) onSaved(res);
  };
  return (
    <form className="card form-card" onSubmit={save}>
      <Field label="Nama gym"><input required minLength={3} value={f.name} onChange={set('name')} /></Field>
      <div className="grid2">
        <Field label="Kota"><input required value={f.city} onChange={set('city')} /></Field>
        <Field label="Jam buka"><input required value={f.openHours} onChange={set('openHours')} /></Field>
      </div>
      <Field label="Alamat"><input required value={f.address} onChange={set('address')} /></Field>
      <Field label="Telepon"><input value={f.phone} onChange={set('phone')} /></Field>
      <div><button className="btn btn-dark" disabled={busy}>{busy ? 'Menyimpan…' : 'Simpan perubahan'}</button></div>
    </form>
  );
}

function FacilitiesTab({ gym, reload }: { gym: Gym; reload: () => void }) {
  const [edit, setEdit] = useState<Partial<Facility> | null>(null);
  const [del, setDel] = useState<Facility | null>(null);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!edit) return;
    const body = { label: edit.label, icon: edit.icon ?? 'fitness_center' };
    const ok = await withToast(
      edit.id ? api.patch(`/admin/gym/facilities/${edit.id}`, body) : api.post('/admin/gym/facilities', body),
      { loading: 'Menyimpan…', success: edit.id ? 'Fasilitas diperbarui' : 'Fasilitas ditambahkan' },
    );
    if (ok) { setEdit(null); reload(); }
  };

  return (
    <div className="card">
      <div className="card-head">
        <h3>Fasilitas ({gym.facilities.length})</h3>
        <button className="btn btn-dark" onClick={() => setEdit({ label: '', icon: 'fitness_center' })}>+ Tambah</button>
      </div>
      {gym.facilities.length === 0 ? <Empty icon="🚿" title="Belum ada fasilitas" text="Tambahkan fasilitas seperti loker, shower, atau Wi-Fi." /> : (
        <ul className="list">
          {gym.facilities.map((x) => (
            <li key={x.id}>
              <span className="glyph">{glyphOf(x.icon)}</span>
              <span className="grow">{x.label}</span>
              <button className="btn btn-sm btn-ghost" onClick={() => setEdit(x)}>Ubah</button>
              <button className="btn btn-sm btn-ghost danger" onClick={() => setDel(x)}>Hapus</button>
            </li>
          ))}
        </ul>
      )}
      {edit && (
        <Modal title={edit.id ? 'Ubah fasilitas' : 'Tambah fasilitas'} onClose={() => setEdit(null)}>
          <form onSubmit={save} className="stack">
            <Field label="Nama fasilitas"><input required autoFocus minLength={2} value={edit.label ?? ''} onChange={(e) => setEdit({ ...edit, label: e.target.value })} /></Field>
            <Field label="Ikon (tampil di aplikasi)">
              <select value={edit.icon} onChange={(e) => setEdit({ ...edit, icon: e.target.value })}>
                {FACILITY_ICONS.map((i) => <option key={i.value} value={i.value}>{i.glyph} {i.label}</option>)}
              </select>
            </Field>
            <div className="modal-actions"><button type="button" className="btn btn-ghost" onClick={() => setEdit(null)}>Batal</button><button className="btn btn-dark">Simpan</button></div>
          </form>
        </Modal>
      )}
      {del && (
        <Confirm title="Hapus fasilitas?" message={`"${del.label}" akan dihapus dari cabang Anda.`}
          onClose={() => setDel(null)}
          onConfirm={async () => { if (await withToast(api.del(`/admin/gym/facilities/${del.id}`), { loading: 'Menghapus…', success: 'Fasilitas dihapus' })) reload(); }} />
      )}
    </div>
  );
}

function PlansTab({ gym, reload }: { gym: Gym; reload: () => void }) {
  const blank = { name: '', price: 0, durationDays: 30, note: '', isPopular: false };
  const [edit, setEdit] = useState<(Partial<Plan> & typeof blank) | null>(null);
  const [del, setDel] = useState<Plan | null>(null);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!edit) return;
    const body = { name: edit.name, price: Number(edit.price), durationDays: Number(edit.durationDays), note: edit.note, isPopular: edit.isPopular };
    const ok = await withToast(
      edit.id ? api.patch(`/admin/gym/plans/${edit.id}`, body) : api.post('/admin/gym/plans', body),
      { loading: 'Menyimpan…', success: edit.id ? 'Paket diperbarui' : 'Paket ditambahkan' },
    );
    if (ok) { setEdit(null); reload(); }
  };

  return (
    <div className="card">
      <div className="card-head">
        <h3>Paket harga ({gym.plans.length})</h3>
        <button className="btn btn-dark" onClick={() => setEdit({ ...blank })}>+ Tambah paket</button>
      </div>
      {gym.plans.length === 0 ? <Empty icon="🏷️" title="Belum ada paket" text="Tanpa paket, member belum bisa berlangganan di aplikasi." /> : (
        <div className="plan-grid">
          {gym.plans.map((p) => (
            <div className={`plan ${p.isPopular ? 'popular' : ''}`} key={p.id}>
              {p.isPopular && <span className="pop-tag">Terpopuler</span>}
              <h4>{p.name}</h4>
              <strong>{rupiah(p.price)}</strong>
              <small className="muted">{p.durationDays} hari{p.note ? ` · ${p.note}` : ''}</small>
              <div className="row-actions">
                <button className="btn btn-sm btn-ghost" onClick={() => setEdit({ ...blank, ...p })}>Ubah</button>
                <button className="btn btn-sm btn-ghost danger" onClick={() => setDel(p)}>Hapus</button>
              </div>
            </div>
          ))}
        </div>
      )}
      {edit && (
        <Modal title={edit.id ? 'Ubah paket' : 'Tambah paket'} onClose={() => setEdit(null)}>
          <form onSubmit={save} className="stack">
            <Field label="Nama paket"><input required autoFocus minLength={2} value={edit.name} onChange={(e) => setEdit({ ...edit, name: e.target.value })} placeholder="Bulanan" /></Field>
            <div className="grid2">
              <Field label="Harga (Rp)"><input type="number" min={0} step={1000} required value={edit.price} onChange={(e) => setEdit({ ...edit, price: Number(e.target.value) })} /></Field>
              <Field label="Durasi (hari)"><input type="number" min={1} required value={edit.durationDays} onChange={(e) => setEdit({ ...edit, durationDays: Number(e.target.value) })} /></Field>
            </div>
            <Field label="Catatan"><input value={edit.note} onChange={(e) => setEdit({ ...edit, note: e.target.value })} placeholder="Akses semua alat" /></Field>
            <label className="check"><input type="checkbox" checked={edit.isPopular} onChange={(e) => setEdit({ ...edit, isPopular: e.target.checked })} /> Tandai sebagai paket terpopuler</label>
            <div className="modal-actions"><button type="button" className="btn btn-ghost" onClick={() => setEdit(null)}>Batal</button><button className="btn btn-dark">Simpan</button></div>
          </form>
        </Modal>
      )}
      {del && (
        <Confirm title="Hapus paket?" message={`Paket "${del.name}" akan dihapus. Paket yang sudah pernah dibeli member tidak bisa dihapus.`}
          onClose={() => setDel(null)}
          onConfirm={async () => { if (await withToast(api.del(`/admin/gym/plans/${del.id}`), { loading: 'Menghapus…', success: 'Paket dihapus' })) reload(); }} />
      )}
    </div>
  );
}

function PhotosTab({ gym, onChange }: { gym: Gym; onChange: (g: Gym) => void }) {
  const input = useRef<HTMLInputElement>(null);
  const [del, setDel] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const upload = async (files: FileList | null) => {
    if (!files?.length) return;
    const list = Array.from(files);
    if (gym.images.length + list.length > 12) return void toast.error('Maksimal 12 foto per cabang');
    const bad = list.find((x) => x.size > 3 * 1024 * 1024 || !['image/jpeg', 'image/png', 'image/webp'].includes(x.type));
    if (bad) return void toast.error(`${bad.name}: harus JPG/PNG/WEBP dan maks 3 MB`);
    const fd = new FormData();
    list.slice(0, 6).forEach((x) => fd.append('images', x));
    setBusy(true);
    const res = await withToast(api.post<Gym>('/admin/gym/images', fd), { loading: 'Mengunggah foto…', success: 'Foto ditambahkan' });
    setBusy(false);
    if (res) onChange(res);
    if (input.current) input.current.value = '';
  };

  return (
    <div className="card">
      <div className="card-head">
        <h3>Foto fasilitas ({gym.images.length})</h3>
        <button className="btn btn-dark" disabled={busy} onClick={() => input.current?.click()}>+ Unggah foto</button>
        <input ref={input} type="file" hidden multiple accept="image/jpeg,image/png,image/webp" onChange={(e) => void upload(e.target.files)} />
      </div>
      {gym.images.length === 0 ? <Empty icon="📷" title="Belum ada foto" text="Foto pertama menjadi sampul cabang di aplikasi." /> : (
        <div className="thumbs big">
          {gym.images.map((im) => (
            <div className="thumb" key={im.id}>
              <img src={imgUrl(im.url)} alt="Foto fasilitas" />
              {im.url === gym.imageUrl && <span className="cover-tag">Sampul</span>}
              <button aria-label="Hapus foto" onClick={() => setDel(im.id)}>✕</button>
            </div>
          ))}
        </div>
      )}
      {del && (
        <Confirm title="Hapus foto?" message="Foto akan dihapus dari cabang dan aplikasi." onClose={() => setDel(null)}
          onConfirm={async () => {
            const res = await withToast(api.del<Gym>(`/admin/gym/images/${del}`), { loading: 'Menghapus…', success: 'Foto dihapus' });
            if (res) onChange(res);
          }} />
      )}
    </div>
  );
}
