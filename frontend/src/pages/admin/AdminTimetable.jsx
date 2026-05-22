import { useEffect, useState } from 'react';
import { adminApi } from '../../services/api';

export default function AdminTimetable() {
  const [entries, setEntries] = useState([]);
  const [routes, setRoutes] = useState([]);
  const [buses, setBuses] = useState([]);
  const [form, setForm] = useState({
    routeId: '',
    busId: '',
    departureTime: '07:00',
    label: '',
    direction: '',
  });
  const [scheduleInput, setScheduleInput] = useState([]);
  const [msg, setMsg] = useState('');

  const load = async () => {
    const [t, r, b] = await Promise.all([
      adminApi.timetable(),
      adminApi.routes(),
      adminApi.buses(),
    ]);
    setEntries(t.data.timetables || []);
    setRoutes(r.data.routes || []);
    setBuses(b.data.buses || []);
  };

  useEffect(() => {
    load();
  }, []);

  const handleRouteChange = (routeId) => {
    setForm(prev => ({ ...prev, routeId }));
    const r = routes.find((x) => x._id === routeId);
    if (r) {
      const inputs = r.stops.map((s, idx) => {
        // s.estimatedTime in route is cumulative minutes from route start stop.
        // Fallback to sequential 8 minutes if undefined/null.
        const mins = typeof s.estimatedTime === 'number' ? s.estimatedTime : idx * 8;
        return {
          stopName: s.name,
          time: addMinutes(form.departureTime, mins),
        };
      });
      setScheduleInput(inputs);
    } else {
      setScheduleInput([]);
    }
  };

  const handleDepartureTimeChange = (departureTime) => {
    setForm(prev => ({ ...prev, departureTime }));
    const r = routes.find((x) => x._id === form.routeId);
    if (r) {
      const updated = scheduleInput.map((s, idx) => {
        const stopDef = r.stops.find((x) => x.name === s.stopName);
        const mins = stopDef && typeof stopDef.estimatedTime === 'number' ? stopDef.estimatedTime : idx * 8;
        return {
          ...s,
          time: addMinutes(departureTime, mins),
        };
      });
      setScheduleInput(updated);
    }
  };

  const autoRecalculateTimes = () => {
    const r = routes.find((x) => x._id === form.routeId);
    if (!r) return;
    const updated = scheduleInput.map((s, idx) => {
      const stopDef = r.stops.find((x) => x.name === s.stopName);
      const mins = stopDef && typeof stopDef.estimatedTime === 'number' ? stopDef.estimatedTime : idx * 8;
      return {
        ...s,
        time: addMinutes(form.departureTime, mins),
      };
    });
    setScheduleInput(updated);
  };

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
        bus: form.busId || undefined,
        departureTime: form.departureTime,
        label: form.label || `Service ${form.departureTime}`,
        direction: form.direction || route.routeName,
        schedule: scheduleInput.map((s, i) => ({
          stopName: s.stopName,
          arrivalTime: s.time,
          order: i + 1,
        })),
      });
      setMsg('Timetable entry added successfully!');
      // Reset form fields but keep loaded state
      setForm({
        routeId: '',
        busId: '',
        departureTime: '07:00',
        label: '',
        direction: '',
      });
      setScheduleInput([]);
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed to create timetable');
    }
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Timetable</h2>
      <p className="text-slate-500 text-sm mt-1">Set departure times per route — passengers see these in the app.</p>

      <form onSubmit={submit} className="mt-6 bg-white rounded-2xl border p-6 flex flex-col gap-4">
        <div className="grid md:grid-cols-2 gap-4">
          <div className="md:col-span-2 flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Route</label>
            <select
              value={form.routeId}
              onChange={(e) => handleRouteChange(e.target.value)}
              className="border rounded-lg px-3 py-2 w-full bg-white"
              required
            >
              <option value="">Select route</option>
              {routes.map((r) => (
                <option key={r._id} value={r._id}>
                  {r.routeNumber} — {r.routeName}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Bus (Optional)</label>
            <select
              value={form.busId}
              onChange={(e) => setForm({ ...form, busId: e.target.value })}
              className="border rounded-lg px-3 py-2 w-full bg-white"
            >
              <option value="">Unassigned / Any Bus</option>
              {buses.map((b) => (
                <option key={b._id} value={b._id}>
                  {b.busName} — {b.busNumber}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Departure Time</label>
            <input
              type="time"
              value={form.departureTime}
              onChange={(e) => handleDepartureTimeChange(e.target.value)}
              className="border rounded-lg px-3 py-2 w-full"
              required
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Direction (Optional)</label>
            <input
              placeholder="e.g. Bus Stand to College"
              value={form.direction}
              onChange={(e) => setForm({ ...form, direction: e.target.value })}
              className="border rounded-lg px-3 py-2 w-full"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Trip Label (Optional)</label>
            <input
              placeholder="e.g. Morning Service"
              value={form.label}
              onChange={(e) => setForm({ ...form, label: e.target.value })}
              className="border rounded-lg px-3 py-2 w-full"
            />
          </div>
        </div>

        {scheduleInput.length > 0 && (
          <div className="mt-4 p-4 border rounded-xl bg-slate-50">
            <div className="flex justify-between items-center mb-2">
              <h3 className="font-semibold text-sm text-slate-700">Set Stop Arrival Times</h3>
              <button
                type="button"
                onClick={autoRecalculateTimes}
                className="text-xs font-bold text-teal-600 hover:text-teal-700 bg-white border border-teal-200 px-3 py-1 rounded-lg shadow-sm"
              >
                🔄 Recalculate Times
              </button>
            </div>
            <p className="text-xs text-slate-500 mb-4">
              Times are **automatically pre-filled** based on the route's stop distances. You can adjust them manually if needed.
            </p>
            <div className="space-y-2">
              {scheduleInput.map((s, idx) => (
                <div key={idx} className="flex items-center justify-between bg-white p-2.5 rounded-lg border border-slate-200 shadow-sm">
                  <span className="font-medium text-sm text-slate-800">
                    {idx + 1}. {s.stopName}
                  </span>
                  <input
                    type="time"
                    value={s.time}
                    onChange={(e) => {
                      const newSched = [...scheduleInput];
                      newSched[idx].time = e.target.value;
                      setScheduleInput(newSched);
                    }}
                    className="border rounded-lg px-2.5 py-1 text-sm font-semibold text-slate-700"
                    required
                  />
                </div>
              ))}
            </div>
          </div>
        )}

        <button type="submit" className="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2.5 rounded-lg font-semibold transition mt-2 shadow-md">
          Add Timetable Entry
        </button>
        {msg && (
          <p className="text-sm font-medium text-teal-700 bg-teal-50 px-4 py-2 rounded-lg border border-teal-200 mt-2">
            {msg}
          </p>
        )}
      </form>

      <div className="mt-8 bg-white rounded-2xl border overflow-hidden shadow-sm">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left border-b">
            <tr>
              <th className="p-3 text-xs font-bold uppercase tracking-wider text-slate-500">Route</th>
              <th className="p-3 text-xs font-bold uppercase tracking-wider text-slate-500">Bus Assigned</th>
              <th className="p-3 text-xs font-bold uppercase tracking-wider text-slate-500">Departure</th>
              <th className="p-3 text-xs font-bold uppercase tracking-wider text-slate-500">Direction</th>
              <th className="p-3 text-xs font-bold uppercase tracking-wider text-slate-500">Stops Timeline</th>
              <th className="p-3"></th>
            </tr>
          </thead>
          <tbody>
            {entries
              .filter((e) => e.isActive !== false)
              .map((e) => (
                <tr key={e._id} className="border-t hover:bg-slate-50 transition">
                  <td className="p-3 font-semibold text-slate-800">
                    <span className="bg-slate-100 px-2 py-1 rounded text-xs font-bold text-slate-600 mr-2 border">
                      {e.route?.routeNumber || 'R'}
                    </span>
                    {e.route?.routeName}
                  </td>
                  <td className="p-3">
                    {e.bus ? (
                      <span className="inline-flex items-center bg-orange-50 text-orange-700 px-2.5 py-1 rounded-lg text-xs font-bold border border-orange-200">
                        🚌 {e.bus.busName} ({e.bus.busNumber})
                      </span>
                    ) : (
                      <span className="text-xs text-slate-400 font-medium italic">Unassigned / Any Bus</span>
                    )}
                  </td>
                  <td className="p-3 font-bold text-teal-600">{e.departureTime}</td>
                  <td className="p-3 text-slate-600">{e.direction || '—'}</td>
                  <td className="p-3 text-slate-500 font-medium">
                    <div className="flex flex-wrap gap-1">
                      {(e.schedule || []).map((s, idx) => (
                        <span key={idx} className="bg-slate-50 border px-1.5 py-0.5 rounded text-xs">
                          {s.stopName} ({s.arrivalTime})
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="p-3 text-right">
                    <button
                      type="button"
                      className="text-red-600 hover:text-red-700 font-bold hover:underline"
                      onClick={async () => {
                        if (window.confirm('Are you sure you want to remove this schedule?')) {
                          await adminApi.deleteTimetable(e._id);
                          load();
                        }
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
  if (!hhmm) return '07:00';
  const [h, m] = hhmm.split(':').map(Number);
  const total = h * 60 + m + mins;
  const nh = Math.floor(total / 60) % 24;
  const nm = total % 60;
  return `${String(nh).padStart(2, '0')}:${String(nm).padStart(2, '0')}`;
}
