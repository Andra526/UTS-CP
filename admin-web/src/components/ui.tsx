import { useEffect, type ReactNode } from 'react';

export function Logo({ light = false }: { light?: boolean }) {
  return (
    <span className={`logo ${light ? 'logo-light' : ''}`}>
      <span className="logo-mark">
        <svg viewBox="0 0 32 32" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round">
          <path d="M6 13v6M10 10v12M22 10v12M26 13v6M10 16h12" />
        </svg>
      </span>
      GymFit
    </span>
  );
}

export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);
  return (
    <div className="overlay" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-head">
          <h3>{title}</h3>
          <button className="icon-btn" onClick={onClose} aria-label="Tutup">✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Confirm({
  title, message, confirmLabel = 'Hapus', onConfirm, onClose,
}: { title: string; message: string; confirmLabel?: string; onConfirm: () => void; onClose: () => void }) {
  return (
    <Modal title={title} onClose={onClose}>
      <p className="muted">{message}</p>
      <div className="modal-actions">
        <button className="btn btn-ghost" onClick={onClose}>Batal</button>
        <button className="btn btn-danger" onClick={() => { onClose(); onConfirm(); }}>{confirmLabel}</button>
      </div>
    </Modal>
  );
}

export function Field({ label, hint, children }: { label: string; hint?: string; children: ReactNode }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      {children}
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  );
}

export function PageHead({ title, sub, action }: { title: string; sub?: string; action?: ReactNode }) {
  return (
    <div className="page-head">
      <div>
        <h1>{title}</h1>
        {sub && <p className="muted">{sub}</p>}
      </div>
      {action}
    </div>
  );
}

export function Empty({ icon = '🗂️', title, text }: { icon?: string; title: string; text?: string }) {
  return (
    <div className="empty">
      <div className="empty-icon">{icon}</div>
      <strong>{title}</strong>
      {text && <p className="muted">{text}</p>}
    </div>
  );
}

export function Loading() {
  return <div className="loading"><span className="spinner" /> Memuat…</div>;
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="empty">
      <div className="empty-icon">⚠️</div>
      <strong>Gagal memuat data</strong>
      <p className="muted">{message}</p>
      <button className="btn btn-dark" onClick={onRetry}>Coba lagi</button>
    </div>
  );
}

export const Badge = ({ tone, children }: { tone: 'green' | 'gray' | 'amber' | 'red' | 'blue'; children: ReactNode }) => (
  <span className={`badge badge-${tone}`}>{children}</span>
);
