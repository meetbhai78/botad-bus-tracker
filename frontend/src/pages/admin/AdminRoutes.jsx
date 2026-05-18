import { useEffect, useState } from 'react';
import { adminApi } from '../../services/api';

export default function AdminRoutes() {
  const [routes, setRoutes] = useState([]);
  const [stops, setStops] = useState([]);
  const [routeNumber, setRouteNumber] = useState('');
  const [routeName, setRouteName] = useState('');
  const [selectedStopIds, setSelectedStopIds] = useState([]);
  const [msg, setMsg] = useState('');

  const load = async () => {
    const [r, s] = await Promise.all([adminApi.routes(), adminApi.stops()]);
    setRoutes(r.data.routes || []);
    setStops((s.data.stops || []).filter((x) => x.isActive !== false));
  };

  useEffect(() => {
    load();
  }, []);

  const toggleStop = (id) => {
    setSelectedStopIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const createRoute = async (e) => {
    e.preventDefault();
    setMsg('');
    if (selectedStopIds.length < 2) {
      setMsg('Select at least 2 stops');
      return;
    }
    
    setMsg('Calculating route...');
    const selectedStops = selectedStopIds.map(id => stops.find(s => s._id === id));
    const coords = selectedStops.map(s => `${s.lng},${s.lat}`).join(';');
    let polyline = '';
    let totalDistanceKm = 0;
    let totalTimeMins = 0;
    
    try {
      const osrmRes = await fetch(`https://router.project-osrm.org/route/v1/driving/${coords}?overview=full`);
      const osrmData = await osrmRes.json();
      if (osrmData.code === 'Ok' && osrmData.routes.length > 0) {
        polyline = osrmData.routes[0].geometry;
        totalDistanceKm = (osrmData.routes[0].distance / 1000).toFixed(2);
        totalTimeMins = Math.ceil(osrmData.routes[0].duration / 60);
      }
    } catch (err) {
      console.error('OSRM fetch failed', err);
    }

    try {
      await adminApi.createRoute({
        routeNumber,
        routeName,
        stops: selectedStopIds.map((stopId, i) => ({ stopId, order: i + 1 })),
        polyline,
        totalDistance: parseFloat(totalDistanceKm) || undefined,
        totalTime: parseInt(totalTimeMins) || undefined,
      });
      setMsg('Route created');
      setRouteNumber('');
      setRouteName('');
      setSelectedStopIds([]);
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed');
    }
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Routes</h2>
      <p className="text-slate-500 text-sm mt-1">Link bus stops in order — like GRTC route planning.</p>

      <form onSubmit={createRoute} className="mt-6 bg-white rounded-2xl border p-6 space-y-4">
        <div className="grid md:grid-cols-2 gap-4">
          <input
            placeholder="Route number (e.g. R1)"
            value={routeNumber}
            onChange={(e) => setRouteNumber(e.target.value)}
            className="border rounded-lg px-3 py-2"
            required
          />
          <input
            placeholder="Route name"
            value={routeName}
            onChange={(e) => setRouteName(e.target.value)}
            className="border rounded-lg px-3 py-2"
            required
          />
        </div>
        <div>
          <p className="text-sm font-medium text-slate-700 mb-2">Stops in order (click to add)</p>
          <div className="flex flex-wrap gap-2">
            {stops.map((s) => (
              <button
                key={s._id}
                type="button"
                onClick={() => toggleStop(s._id)}
                className={`px-3 py-1.5 rounded-full text-sm border ${
                  selectedStopIds.includes(s._id)
                    ? 'bg-teal-600 text-white border-teal-600'
                    : 'bg-white text-slate-700'
                }`}
              >
                {selectedStopIds.includes(s._id)
                  ? `${selectedStopIds.indexOf(s._id) + 1}. `
                  : ''}
                {s.name}
              </button>
            ))}
          </div>
        </div>
        <button type="submit" className="bg-teal-600 text-white px-4 py-2 rounded-lg font-medium">
          Create route
        </button>
        {msg && <p className="text-sm text-teal-700">{msg}</p>}
      </form>

      <div className="mt-8 space-y-4">
        {routes.map((r) => (
          <div key={r._id} className="bg-white rounded-2xl border p-4">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="font-bold">
                  {r.routeNumber} — {r.routeName}
                </h3>
                <p className="text-sm text-slate-500 mt-1">
                  {(r.stops || []).map((s) => s.name).join(' → ')}
                </p>
              </div>
              <button
                type="button"
                className="text-red-600 text-sm"
                onClick={async () => {
                  if (confirm('Delete this route?')) {
                    await adminApi.deleteRoute(r._id);
                    load();
                  }
                }}
              >
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
