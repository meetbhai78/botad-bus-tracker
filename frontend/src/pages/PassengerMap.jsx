import { useCallback, useState } from 'react';
import { Link } from 'react-router-dom';
import { GoogleMap, useJsApiLoader, Marker, InfoWindow } from '@react-google-maps/api';
import { useSocket } from '../hooks/useSocket';

const BOTAD_CENTER = { lat: 22.1647, lng: 71.6661 };
const mapContainerStyle = { width: '100%', height: 'calc(100vh - 56px)' };

export default function PassengerMap() {
  const { buses } = useSocket();
  const [selected, setSelected] = useState(null);
  const mapsKey = import.meta.env.VITE_GOOGLE_MAPS_KEY;

  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: mapsKey || '',
  });

  const onMapLoad = useCallback((map) => {
    map.setCenter(BOTAD_CENTER);
    map.setZoom(14);
  }, []);

  if (!mapsKey) {
    return (
      <div className="p-8 text-center">
        <h1 className="text-xl font-bold">Botad Bus Tracker</h1>
        <p className="mt-2 text-slate-600">
          Set <code className="bg-slate-100 px-1">VITE_GOOGLE_MAPS_KEY</code> in frontend/.env
        </p>
        <p className="mt-4 text-sm">Live buses (no map): {buses.length}</p>
        <ul className="mt-2 text-left max-w-md mx-auto">
          {buses.map((b) => (
            <li key={b.busId} className="border-b py-2">
              {b.busName} — {b.speed ?? 0} km/h {b.eta != null && `· ETA ${b.eta} min`}
            </li>
          ))}
        </ul>
        <Link to="/login" className="text-botad-green mt-4 inline-block">
          Login
        </Link>
      </div>
    );
  }

  return (
    <div>
      <header className="h-14 bg-botad-dark text-white flex items-center justify-between px-4">
        <span className="font-semibold">Botad Bus Tracker</span>
        <div className="flex gap-3 text-sm">
          <span className="text-teal-300">{buses.length} live</span>
          <Link to="/login" className="hover:underline">
            Login
          </Link>
          <Link to="/admin" className="hover:underline">
            Admin
          </Link>
        </div>
      </header>
      {!isLoaded ? (
        <p className="p-8 text-center">Loading map…</p>
      ) : (
        <GoogleMap mapContainerStyle={mapContainerStyle} center={BOTAD_CENTER} zoom={14} onLoad={onMapLoad}>
          {buses.map((bus) => (
            <Marker
              key={bus.busId}
              position={{ lat: bus.lat, lng: bus.lng }}
              label={bus.eta != null ? `${bus.eta}m` : bus.busName?.slice(0, 2) || 'B'}
              onClick={() => setSelected(bus)}
            />
          ))}
          {selected && (
            <InfoWindow
              position={{ lat: selected.lat, lng: selected.lng }}
              onCloseClick={() => setSelected(null)}
            >
              <div className="text-sm text-slate-800">
                <strong>{selected.busName}</strong>
                <br />
                Speed: {selected.speed ?? '—'} km/h
                <br />
                ETA: {selected.eta ?? '—'} min
                <br />
                Seats: {selected.seatsAvailable ?? '—'}
              </div>
            </InfoWindow>
          )}
        </GoogleMap>
      )}
    </div>
  );
}
