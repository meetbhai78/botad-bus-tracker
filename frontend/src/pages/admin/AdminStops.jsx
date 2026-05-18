import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { adminApi } from '../../services/api';

// Fix for default marker icon in react-leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const empty = { name: '', lat: '', lng: '', address: '' };
const BOTAD_CENTER = [22.1647, 71.6661];

function MapClickHandler({ setForm, form }) {
  useMapEvents({
    click(e) {
      const lat = e.latlng.lat.toFixed(6);
      const lng = e.latlng.lng.toFixed(6);
      setForm({ ...form, lat, lng });
    },
  });
  return null;
}

export default function AdminStops() {
  const [stops, setStops] = useState([]);
  const [form, setForm] = useState(empty);
  const [editing, setEditing] = useState(null);
  const [msg, setMsg] = useState('');

  const load = () => adminApi.stops().then((r) => setStops(r.data.stops || []));

  useEffect(() => {
    load();
  }, []);

  const submit = async (e) => {
    e.preventDefault();
    setMsg('');
    const payload = {
      name: form.name,
      lat: parseFloat(form.lat),
      lng: parseFloat(form.lng),
      address: form.address,
    };
    try {
      if (editing) {
        await adminApi.updateStop(editing, payload);
        setMsg('Stop updated');
      } else {
        await adminApi.createStop(payload);
        setMsg('Stop added');
      }
      setForm(empty);
      setEditing(null);
      load();
    } catch (err) {
      setMsg(err.response?.data?.message || 'Failed');
    }
  };

  const startEdit = (s) => {
    setEditing(s._id);
    setForm({
      name: s.name,
      lat: String(s.lat),
      lng: String(s.lng),
      address: s.address || '',
    });
  };

  return (
    <div className="p-8 max-w-5xl">
      <h2 className="text-2xl font-bold text-slate-900">Bus stops</h2>
      <p className="text-slate-500 text-sm mt-1">Add stops with GPS location — used in routes & passenger nearby search. Click on the map to set coordinates!</p>

      <div className="mt-6 rounded-2xl overflow-hidden border h-80 z-0 relative">
        <MapContainer center={BOTAD_CENTER} zoom={14} style={{ width: '100%', height: '100%' }}>
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; OpenStreetMap contributors'
          />
          <MapClickHandler setForm={setForm} form={form} />
          {form.lat && form.lng && !isNaN(parseFloat(form.lat)) && !isNaN(parseFloat(form.lng)) && (
            <Marker position={[parseFloat(form.lat), parseFloat(form.lng)]} />
          )}
          {stops.map((s) => (
            <Marker key={s._id} position={[s.lat, s.lng]}>
              <Popup>{s.name}</Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      <form onSubmit={submit} className="mt-6 bg-white rounded-2xl border border-slate-200 p-6 grid md:grid-cols-2 gap-4">
        <input
          placeholder="Stop name"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          className="border rounded-lg px-3 py-2 md:col-span-2"
          required
        />
        <input
          placeholder="Latitude"
          value={form.lat}
          onChange={(e) => setForm({ ...form, lat: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <input
          placeholder="Longitude"
          value={form.lng}
          onChange={(e) => setForm({ ...form, lng: e.target.value })}
          className="border rounded-lg px-3 py-2"
          required
        />
        <input
          placeholder="Address (optional)"
          value={form.address}
          onChange={(e) => setForm({ ...form, address: e.target.value })}
          className="border rounded-lg px-3 py-2 md:col-span-2"
        />
        <div className="md:col-span-2 flex gap-2">
          <button type="submit" className="bg-teal-600 text-white px-4 py-2 rounded-lg font-medium">
            {editing ? 'Update stop' : 'Add stop'}
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
              <th className="p-3">Name</th>
              <th className="p-3">Lat</th>
              <th className="p-3">Lng</th>
              <th className="p-3">Status</th>
              <th className="p-3"></th>
            </tr>
          </thead>
          <tbody>
            {stops.map((s) => (
              <tr key={s._id} className="border-t">
                <td className="p-3 font-medium">{s.name}</td>
                <td className="p-3">{s.lat}</td>
                <td className="p-3">{s.lng}</td>
                <td className="p-3">
                  <span className={s.isActive ? 'text-green-700' : 'text-slate-400'}>
                    {s.isActive ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="p-3 space-x-2">
                  <button type="button" className="text-teal-600" onClick={() => startEdit(s)}>
                    Edit
                  </button>
                  {s.isActive && (
                    <button
                      type="button"
                      className="text-red-600"
                      onClick={async () => {
                        await adminApi.deleteStop(s._id);
                        load();
                      }}
                    >
                      Deactivate
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

