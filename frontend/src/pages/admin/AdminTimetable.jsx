import { useEffect, useState } from 'react';
import { adminApi } from '../../services/api';

export default function AdminTimetable() {
  const [entries, setEntries] = useState([]);
  const [routes, setRoutes] = useState([]);
  const [form, setForm] = useState({
    routeId: '',
    departureTime: '07:00',
    label: '',
    direction: '',
  });
  const [msg, setMsg] = useState('');

  const load = async () => {
    const [t, r] = await Promise.all([adminApi.timetable(), adminApi.routes()]);
    setEntries(t.data.timetables || []);
    setRoutes(r.data.routes || []);
  };

  useEffect(() => {
    load();
  }, []);

  const submit = async (e) => {
    e.preventDefault();
    setMsg('');
    const route = routes.find((x) => x._id === form.routeId);
    if (!route) {
      setMsg('Select a route');
      return;
    }
    try {
      await adminApi.createTimetable({
        route: form.routeId,
        departureTime: form.departureTime,
        label: form.label || `Service ${form.departureTime}`,
        direction: form.direction || route.routeName,
        schedule: (route.stops || []).map((s, i) => ({
          stopName: s.name,
          arrivalTime: addMinutes(form.departureTime, (s.estimatedTime ?? i * 8)),
          order: s.order ?? i + 1,
        })),
      });
      setMsg('Timetable entry added');
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed');
    }
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Timetable</h2>
      <p className="text-slate-500 text-sm mt-1">Set departure times per route — passengers see these in the app.</p>

      <form onSubmit={submit} className="mt-6 bg-white rounded-2xl border p-6 grid md:grid-cols-2 gap-4">
        <select
          value={form.routeId}
          onChange={(e) => setForm({ ...form, routeId: e.target.value })}
          className="border rounded-lg px-3 py-2 md:col-span-2"
          required
        >
          <option value="">Select route</option>
          {routes.map((r) => (
            <option key={r._id} value={r._id}>
              {r.routeNumber} — {r.routeName}
            </option>
          ))}
        </select>
        <input
          type="time"
          value={form.departureTime}
          onChange={(e) => setForm({ ...form, departureTime: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <input
          placeholder="Direction (optional)"
          value={form.direction}
          onChange={(e) => setForm({ ...form, direction: e.target.value })}
          className="border rounded-lg px-3 py-2"
        />
        <input
          placeholder="Label (optional)"
          value={form.label}
          onChange={(e) => setForm({ ...form, label: e.target.value })}
          className="border rounded-lg px-3 py-2 md:col-span-2"
        />
        <button type="submit" className="bg-teal-600 text-white px-4 py-2 rounded-lg font-medium md:col-span-2">
          Add timetable
        </button>
        {msg && <p className="text-sm text-teal-700 md:col-span-2">{msg}</p>}
      </form>

      <div className="mt-8 bg-white rounded-2xl border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Route</th>
              <th className="p-3">Departure</th>
              <th className="p-3">Direction</th>
              <th className="p-3">Stops</th>
              <th className="p-3"></th>
            </tr>
          </thead>
          <tbody>
            {entries
              .filter((e) => e.isActive !== false)
              .map((e) => (
                <tr key={e._id} className="border-t">
                  <td className="p-3 font-medium">
                    {e.route?.routeNumber} {e.route?.routeName}
                  </td>
                  <td className="p-3">{e.departureTime}</td>
                  <td className="p-3">{e.direction || '—'}</td>
                  <td className="p-3 text-slate-500">
                    {(e.schedule || []).map((s) => `${s.stopName} ${s.arrivalTime}`).join(', ')}
                  </td>
                  <td className="p-3">
                    <button
                      type="button"
                      className="text-red-600"
                      onClick={async () => {
                        await adminApi.deleteTimetable(e._id);
                        load();
                      }}
                    >
                      Remove
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

function addMinutes(hhmm, mins) {
  const [h, m] = hhmm.split(':').map(Number);
  const total = h * 60 + m + mins;
  const nh = Math.floor(total / 60) % 24;
  const nm = total % 60;
  return `${String(nh).padStart(2, '0')}:${String(nm).padStart(2, '0')}`;
}
