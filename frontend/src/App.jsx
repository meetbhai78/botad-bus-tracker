import { Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import PassengerMap from './pages/PassengerMap';
import AdminDashboard from './pages/AdminDashboard';

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
            <AdminDashboard />
          </PrivateRoute>
        }
      />
    </Routes>
  );
}
