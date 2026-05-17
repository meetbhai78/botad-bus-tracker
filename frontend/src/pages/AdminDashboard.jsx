import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { GoogleMap, useJsApiLoader, Marker } from '@react-google-maps/api';
import { adminApi } from '../services/api';
import { useSocket } from '../hooks/useSocket';

const BOTAD_CENTER = { lat: 22.1647, lng: 71.6661 };

export default function AdminDashboard() {
  const navigate = useNavigate();
  const { buses } = useSocket();
  const [stats, setStats] = useState(null);
  const [busList, setBusList] = useState([]);
  const mapsKey = import.meta.env.VITE_GOOGLE_MAPS_KEY;
  const { isLoaded } = useJsApiLoader({ googleMapsApiKey: mapsKey || '' });

  useEffect(() => {
    adminApi
      .dashboard()
      .then((r) => setStats(r.data.stats))
      .catch(() => navigate('/login'));
    adminApi.buses().then((r) => setBusList(r.data.buses));
  }, [navigate]);

  const chartData = [
    { hour: '6', passengers: 12 },
    { hour: '8', passengers: 45 },
    { hour: '10', passengers: 28 },
    { hour: '12', passengers: 35 },
    { hour: '17', passengers: 52 },
    { hour: '19', passengers: 38 },
  ];

  const cards = [
    { label: 'Live buses', value: stats?.activeBuses ?? '—', link: null },
    { label: 'Passengers today', value: stats?.passengersToday ?? '—', link: '/admin/users' },
    { label: 'Revenue (₹)', value: stats?.revenue ?? '—', link: null },
    { label: 'Routes', value: stats?.routes ?? '—', link: '/admin/routes' },
  ];

  return (
    <div className="p-8 max-w-6xl">
      <h2 className="text-2xl font-bold text-slate-900">Dashboard</h2>
      <p className="text-slate-500 text-sm mt-1">Botad city bus — overview</p>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mt-6">
        {cards.map((c) => (
          <div key={c.label} className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm">{c.label}</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{c.value}</p>
            {c.link && (
              <Link to={c.link} className="text-teal-600 text-xs mt-2 inline-block hover:underline">
                Manage →
              </Link>
            )}
          </div>
        ))}
      </div>

      <div className="grid lg:grid-cols-2 gap-6 mt-6">
        <div className="bg-white rounded-2xl p-4 border h-80">
          <h3 className="font-semibold mb-2">Live map</h3>
          {mapsKey && isLoaded ? (
            <GoogleMap
              mapContainerStyle={{ width: '100%', height: 'calc(100% - 2rem)' }}
              center={BOTAD_CENTER}
              zoom={13}
            >
              {buses.map((b) => (
                <Marker key={b.busId} position={{ lat: b.lat, lng: b.lng }} />
              ))}
            </GoogleMap>
          ) : (
            <p className="text-slate-500 text-sm">Add VITE_GOOGLE_MAPS_KEY for live map</p>
          )}
        </div>
        <div className="bg-white rounded-2xl p-4 border h-80">
          <h3 className="font-semibold mb-2">Passengers per hour</h3>
          <ResponsiveContainer width="100%" height="90%">
            <BarChart data={chartData}>
              <XAxis dataKey="hour" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="passengers" fill="#0d9488" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-white rounded-2xl border mt-6 overflow-hidden">
        <h3 className="font-semibold p-4 border-b">Fleet</h3>
        <table className="w-full text-sm">
          <thead className="bg-slate-50">
            <tr>
              <th className="text-left p-3">Number</th>
              <th className="text-left p-3">Name</th>
              <th className="text-left p-3">Status</th>
              <th className="text-left p-3">Live</th>
            </tr>
          </thead>
          <tbody>
            {busList.map((b) => (
              <tr key={b._id} className="border-t">
                <td className="p-3">{b.busNumber}</td>
                <td className="p-3">{b.busName}</td>
                <td className="p-3">
                  <span
                    className={`px-2 py-0.5 rounded text-xs ${
                      b.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-slate-100'
                    }`}
                  >
                    {b.status}
                  </span>
                </td>
                <td className="p-3">{b.isLive ? 'Yes' : 'No'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
