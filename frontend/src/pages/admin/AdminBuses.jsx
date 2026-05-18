import { useEffect, useState } from 'react';
import { adminApi } from '../../services/api';

const empty = { busNumber: '', busName: '', capacity: 50, driver: '', route: '' };

export default function AdminBuses() {
  const [buses, setBuses] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [routes, setRoutes] = useState([]);
  const [form, setForm] = useState(empty);
  const [editing, setEditing] = useState(null);
  const [msg, setMsg] = useState('');

  const load = async () => {
    const [b, d, r] = await Promise.all([
      adminApi.buses(),
      adminApi.drivers(),
      adminApi.routes(),
    ]);
    setBuses(b.data.buses || []);
    setDrivers(d.data.drivers || []);
    setRoutes(r.data.routes || []);
  };

  useEffect(() => {
    load();
  }, []);

  const submit = async (e) => {
    e.preventDefault();
    setMsg('');
    const payload = {
      busNumber: form.busNumber,
      busName: form.busName,
      capacity: parseInt(form.capacity),
      driver: form.driver || undefined,
      route: form.route || undefined,
    };
    try {
      if (editing) {
        await adminApi.updateBus(editing, payload);
        setMsg('Bus updated');
      } else {
        await adminApi.createBus(payload);
        setMsg('Bus added');
      }
      setForm(empty);
      setEditing(null);
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed');
    }
  };

  const startEdit = (b) => {
    setEditing(b._id);
    setForm({
      busNumber: b.busNumber,
      busName: b.busName,
      capacity: b.capacity,
      driver: b.driver?._id || '',
      route: b.route?._id || '',
    });
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Buses (Fleet)</h2>
      <p className="text-slate-500 text-sm mt-1">Manage your buses and assign them to a driver and route.</p>

      <form onSubmit={submit} className="mt-6 bg-white rounded-2xl border border-slate-200 p-6 grid md:grid-cols-2 gap-4">
        <input
          placeholder="Bus number (e.g. GJ-33-MB-6338)"
          value={form.busNumber}
          onChange={(e) => setForm({ ...form, busNumber: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <input
          placeholder="Bus name (e.g. Express 1)"
          value={form.busName}
          onChange={(e) => setForm({ ...form, busName: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <input
          type="number"
          placeholder="Capacity (e.g. 50)"
          value={form.capacity}
          onChange={(e) => setForm({ ...form, capacity: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <select
          value={form.driver}
          onChange={(e) => setForm({ ...form, driver: e.target.value })}
          className="border rounded-lg px-3 py-2"
        >
          <option value="">Select Driver (Optional)</option>
          {drivers.map((d) => (
            <option key={d._id} value={d._id}>
              {d.name} ({d.phone})
            </option>
          ))}
        </select>
        <select
          value={form.route}
          onChange={(e) => setForm({ ...form, route: e.target.value })}
          className="border rounded-lg px-3 py-2 md:col-span-2"
        >
          <option value="">Select Route (Optional)</option>
          {routes.map((r) => (
            <option key={r._id} value={r._id}>
              {r.routeNumber} — {r.routeName}
            </option>
          ))}
        </select>
        <div className="md:col-span-2 flex gap-2">
          <button type="submit" className="bg-teal-600 text-white px-4 py-2 rounded-lg font-medium">
            {editing ? 'Update bus' : 'Add bus'}
          </button>
          {editing && (
            <button
              type="button"
              className="px-4 py-2 rounded-lg border"
              onClick={() => {
                setEditing(null);
                setForm(empty);
              }}
            >
              Cancel
            </button>
          )}
        </div>
        {msg && <p className="text-teal-700 text-sm md:col-span-2">{msg}</p>}
      </form>

      <div className="mt-8 bg-white rounded-2xl border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Bus Number</th>
              <th className="p-3">Bus Name</th>
              <th className="p-3">Driver</th>
              <th className="p-3">Route</th>
              <th className="p-3">Status</th>
              <th className="p-3"></th>
            </tr>
          </thead>
          <tbody>
            {buses.map((b) => (
              <tr key={b._id} className="border-t">
                <td className="p-3 font-medium">{b.busNumber}</td>
                <td className="p-3">{b.busName}</td>
                <td className="p-3">{b.driver ? b.driver.name : 'Unassigned'}</td>
                <td className="p-3">{b.route ? b.route.routeName : 'Unassigned'}</td>
                <td className="p-3">
                  <span className={b.status === 'active' ? 'text-green-700' : 'text-slate-400'}>
                    {b.status}
                  </span>
                </td>
                <td className="p-3 space-x-2">
                  <button type="button" className="text-teal-600" onClick={() => startEdit(b)}>
                    Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
