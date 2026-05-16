import { useEffect, useState, useRef } from 'react';
import { io } from 'socket.io-client';

const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || 'http://localhost:5000';

/** Real-time bus locations — Socket.io hook */
export function useSocket() {
  const [buses, setBuses] = useState([]);
  const socketRef = useRef(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const socket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket'],
    });
    socketRef.current = socket;

    socket.on('buses:locations', (list) => {
      setBuses(list.filter((b) => b.lat && b.lng));
    });

    socket.on('bus:update', (update) => {
      setBuses((prev) => {
        const idx = prev.findIndex((b) => b.busId === update.busId);
        if (idx >= 0) {
          const next = [...prev];
          next[idx] = { ...next[idx], ...update };
          return next;
        }
        return [...prev, update];
      });
    });

    return () => socket.disconnect();
  }, []);

  const watchBus = (busId) => {
    socketRef.current?.emit('passenger:watch', { busId });
  };

  return { buses, watchBus };
}
