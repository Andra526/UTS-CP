import { Navigate, Route, Routes } from 'react-router-dom';
import AdminLayout from './components/AdminLayout';
import Landing from './pages/Landing';
import Login from './pages/Login';
import Register from './pages/Register';
import Bookings from './pages/admin/Bookings';
import Branch from './pages/admin/Branch';
import DashboardPage from './pages/admin/Dashboard';
import Members from './pages/admin/Members';
import Trainers from './pages/admin/Trainers';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/daftar" element={<Register />} />
      <Route path="/masuk" element={<Login />} />
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<DashboardPage />} />
        <Route path="cabang" element={<Branch />} />
        <Route path="trainer" element={<Trainers />} />
        <Route path="member" element={<Members />} />
        <Route path="booking" element={<Bookings />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
