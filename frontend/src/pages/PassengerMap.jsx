import { useState } from 'react';
import { Link } from 'react-router-dom';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useSocket } from '../hooks/useSocket';

// Fix for default marker icon in react-leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const BOTAD_CENTER = [22.1647, 71.6661];

export default function PassengerMap() {
  const { buses } = useSocket();
  const [selected, setSelected] = useState(null);

  return (
    <div>
      <header className="h-14 bg-botad-dark text-white flex items-center justify-between px-4 z-50 relative">
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
      
      <div style={{ width: '100%', height: 'calc(100vh - 56px)', zIndex: 0, position: 'relative' }}>
        <MapContainer center={BOTAD_CENTER} zoom={14} style={{ width: '100%', height: '100%' }}>
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; OpenStreetMap contributors'
          />
          {buses.map((bus) => (
            <Marker
              key={bus.busId}
              position={[bus.lat, bus.lng]}
              eventHandlers={{
                click: () => setSelected(bus),
              }}
            >
              <Popup>
                <div className="text-sm text-slate-800">
                  <strong>{bus.busName || bus.busNumber}</strong>
                  <br />
                  Speed: {bus.speed ?? '—'} km/h
                  <br />
                  ETA: {bus.eta ?? '—'} min
                  <br />
                  Seats: {bus.seatsAvailable ?? '—'}
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
    </div>
  );
}
