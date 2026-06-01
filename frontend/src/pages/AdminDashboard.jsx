import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { adminApi } from '../services/api';
import { useSocket } from '../hooks/useSocket';

// Fix for default marker icon in react-leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const BOTAD_CENTER = [22.1647, 71.6661];

export default function AdminDashboard() {
  const navigate = useNavigate();
  const { buses } = useSocket();
  const [stats, setStats] = useState(null);
  const [busList, setBusList] = useState([]);
  const [chartData, setChartData] = useState([]);
  const [alertConfig, setAlertConfig] = useState({ active: false, message: '' });
  const [isAlertLoading, setIsAlertLoading] = useState(false);
  const [alertFeedback, setAlertFeedback] = useState('');

  useEffect(() => {
    adminApi
      .dashboard()
      .then((r) => setStats(r.data.stats))
      .catch(() => navigate('/login'));
    adminApi.buses().then((r) => setBusList(r.data.buses));
    adminApi.dailyReport().then((r) => setChartData(r.data.report.hourly)).catch(() => setChartData([]));
    adminApi.getEmergencyAlert().then((r) => {
      if (r.data.success && r.data.alert) {
        setAlertConfig(r.data.alert);
      }
    });
  }, [navigate]);

  const handleAlertUpdate = (e) => {
    e.preventDefault();
    setIsAlertLoading(true);
    adminApi.updateEmergencyAlert(alertConfig)
      .then((r) => {
        if (r.data.success) {
          setAlertConfig(r.data.alert);
          setAlertFeedback('Broadcast updated successfully! 🚀');
          setTimeout(() => setAlertFeedback(''), 4000);
        }
      })
      .catch(() => setAlertFeedback('Error updating broadcast alert! ❌'))
      .finally(() => setIsAlertLoading(false));
  };

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

      <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm mt-6">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-xl ${alertConfig.active ? 'bg-red-50 text-red-600' : 'bg-slate-50 text-slate-400'}`}>
            <span className="text-xl">🚨</span>
          </div>
          <div>
            <h3 className="font-bold text-slate-800 text-lg">Emergency Announcement Broadcast</h3>
            <p className="text-slate-500 text-xs">Apne active passenger application users ko immediate warning banner aur pulsating bell notification bhejein.</p>
          </div>
        </div>

        <form onSubmit={handleAlertUpdate} className="mt-4 space-y-4">
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="alertActive"
              checked={alertConfig.active}
              onChange={(e) => setAlertConfig({ ...alertConfig, active: e.target.checked })}
              className="w-4 h-4 text-teal-600 border-slate-300 rounded focus:ring-teal-500 cursor-pointer"
            />
            <label htmlFor="alertActive" className="text-sm font-semibold text-slate-700 cursor-pointer selection:bg-transparent">
              Activate alert popup and pulsating red bell icon on users' Home Screen
            </label>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Emergency Announcement Message</label>
            <textarea
              rows={3}
              value={alertConfig.message}
              onChange={(e) => setAlertConfig({ ...alertConfig, message: e.target.value })}
              placeholder="e.g. Festival rush ke karan buses delay se chalengi..."
              className="w-full text-sm border border-slate-200 rounded-xl p-3 focus:outline-none focus:border-teal-500 focus:ring-1 focus:ring-teal-500 placeholder-slate-400"
              required={alertConfig.active}
            />
          </div>

          <div className="flex items-center justify-between">
            <button
              type="submit"
              disabled={isAlertLoading}
              className={`px-6 py-2.5 rounded-xl font-bold text-sm text-white transition-all shadow-sm ${
                alertConfig.active 
                  ? 'bg-red-600 hover:bg-red-700 shadow-red-100' 
                  : 'bg-teal-600 hover:bg-teal-700 shadow-teal-100'
              } disabled:opacity-50`}
            >
              {isAlertLoading ? 'Updating...' : 'Update Alert Broadcast'}
            </button>

            {alertFeedback && (
              <span className={`text-xs font-semibold px-3 py-1 rounded-full ${
                alertFeedback.includes('successfully') ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
              }`}>
                {alertFeedback}
              </span>
            )}
          </div>
        </form>
      </div>

      <div className="grid lg:grid-cols-2 gap-6 mt-6">
        <div className="bg-white rounded-2xl p-4 border h-80 z-0">
          <h3 className="font-semibold mb-2">Live map</h3>
          <MapContainer center={BOTAD_CENTER} zoom={13} style={{ width: '100%', height: 'calc(100% - 2rem)', borderRadius: '0.5rem' }}>
            <TileLayer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution='&copy; OpenStreetMap contributors'
            />
            {buses.map((b) => (
              <Marker key={b.busId} position={[b.lat, b.lng]}>
                <Popup>{b.busName || b.busNumber}</Popup>
              </Marker>
            ))}
          </MapContainer>
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
