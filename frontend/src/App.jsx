import { Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import PassengerMap from './pages/PassengerMap';
import AdminLayout from './components/AdminLayout';
import AdminDashboard from './pages/AdminDashboard';
import AdminStops from './pages/admin/AdminStops';
import AdminRoutes from './pages/admin/AdminRoutes';
import AdminTimetable from './pages/admin/AdminTimetable';
import AdminUsers from './pages/admin/AdminUsers';

function PrivateRoute({ children, adminOnly }) {
  const token = localStorage.getItem('token');
  const role = localStorage.getItem('role');
  if (!token) return <Navigate to="/login" replace />;
  if (adminOnly && role !== 'admin') return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<PassengerMap />} />
      <Route
        path="/admin"
        element={
          <PrivateRoute adminOnly>
            <AdminLayout />
          </PrivateRoute>
        }
      >
        <Route index element={<AdminDashboard />} />
        <Route path="stops" element={<AdminStops />} />
        <Route path="routes" element={<AdminRoutes />} />
        <Route path="timetable" element={<AdminTimetable />} />
        <Route path="users" element={<AdminUsers />} />
      </Route>
    </Routes>
  );
}
