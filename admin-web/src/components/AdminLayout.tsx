import { useState } from 'react';
import { NavLink, Navigate, Outlet, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuth } from '../auth';
import { Logo, Loading } from './ui';

const NAV = [
  { to: '/admin', end: true, label: 'Ringkasan', icon: '📊' },
  { to: '/admin/cabang', label: 'Kelola Cabang', icon: '🏢' },
  { to: '/admin/trainer', label: 'Personal Trainer', icon: '🏋️' },
  { to: '/admin/member', label: 'Member', icon: '👥' },
  { to: '/admin/booking', label: 'Booking & Sesi', icon: '📅' },
];

export default function AdminLayout() {
  const { user, ready, logout } = useAuth();
  const nav = useNavigate();
  const [leaving, setLeaving] = useState(false);
  if (leaving) return null; // sedang keluar: jangan alihkan ke /masuk
  if (!ready) return <Loading />;
  if (!user) return <Navigate to="/masuk" replace />;

  return (
    <div className="shell">
      <aside className="sidebar">
        <Logo light />
        <nav>
          {NAV.map((n) => (
            <NavLink key={n.to} to={n.to} end={n.end} className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <span aria-hidden>{n.icon}</span> {n.label}
            </NavLink>
          ))}
        </nav>
        <div className="side-foot">
          <div className="who">
            <div className="avatar">{user.name.charAt(0).toUpperCase()}</div>
            <div>
              <strong>{user.name}</strong>
              <small>{user.email}</small>
            </div>
          </div>
          <button
            className="btn btn-ghost-light"
            onClick={() => { setLeaving(true); nav('/'); logout(); toast('Sampai jumpa! 👋'); }}
          >
            Keluar
          </button>
        </div>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
