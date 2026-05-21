const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');
const Bus = require('../models/Bus');
const Trip = require('../models/Trip');
const { isDbReady } = require('../config/db');
const { haversineKm, estimateEtaMinutes } = require('../utils/distance');

const liveBuses = new Map();
const lastDbUpdate = new Map();
let broadcastInterval = null;
let dbWarningShown = false;

function startBroadcast(io) {
  if (broadcastInterval) return;

  broadcastInterval = setInterval(() => {
    if (!isDbReady()) return;
    try {
      if (liveBuses.size === 0) return;
      
      const list = Array.from(liveBuses.values());
      // Emit from memory instead of querying DB every 5 seconds
      io.emit('buses:locations', list);
    } catch (err) {
      console.error('Broadcast error:', err.message);
    }
  }, 5000); // Increased from 3s to 5s for better performance
}

function initSocket(io) {
  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next();
    try {
      if (!isDbReady()) return next();
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-password');
      if (user) socket.user = user;
      next();
    } catch {
      // Invalid/expired token — allow anonymous socket (passenger map + stale localStorage).
      // `driver:location` still requires a valid `socket.user` with role driver.
      socket.user = undefined;
      next();
    }
  });

  io.on('connection', (socket) => {
    console.log('Socket connected:', socket.id);

    socket.on('passenger:watch', ({ busId }) => {
      if (busId) socket.join(`bus:${busId}`);
    });

    socket.on('passenger:watchStop', ({ stopId }) => {
      if (stopId) socket.join(`stop:${stopId}`);
    });

    socket.on('driver:location', async (data) => {
      if (!isDbReady()) return;
      const { busId, lat, lng, speed, heading, tripId } = data;
      if (!socket.user || socket.user.role !== 'driver') return;

      try {
        const bus = await Bus.findById(busId);
        if (!bus || bus.driver?.toString() !== socket.user._id.toString()) return;

        const now = Date.now();
        const lastUpdate = lastDbUpdate.get(busId) || 0;
        const shouldUpdateDb = (now - lastUpdate) > 15000; // 15 seconds throttle

        const updatedAt = new Date();
        let tripMapCount = 0;
        let eta = null;

        if (shouldUpdateDb) {
          bus.currentLocation = { lat, lng, speed, heading, updatedAt };
          bus.isLive = true;
          bus.status = 'active';
          await bus.save();

          if (tripId) {
            const trip = await Trip.findByIdAndUpdate(tripId, {
              $push: { locationHistory: { lat, lng, speed, timestamp: updatedAt } },
            });
            tripMapCount = trip?.passengersCount || 0;
          }

          if (bus.route) {
            const Route = require('../models/Route');
            const { predictEta } = require('../services/etaService');
            const route = await Route.findById(bus.route);
            
            if (route && route.stops && route.stops.length > 0) {
              const hour = updatedAt.getHours();
              for (const stop of route.stops) {
                const etaData = await predictEta({
                  busLat: lat, busLng: lng,
                  stopLat: stop.lat, stopLng: stop.lng,
                  speed, hour
                });
                
                io.to(`stop:${stop._id}`).emit('stop:eta', {
                  stopId: stop._id,
                  busId,
                  etaMinutes: etaData.etaMinutes,
                  distanceKm: etaData.distanceKm,
                  updatedAt
                });
                
                if (!eta && (stop.order === 1 || stop === route.stops[0])) {
                  eta = etaData.etaMinutes;
                }
              }
            }
          }
          lastDbUpdate.set(busId, now);
        } else {
          // Use previous data if not updating DB this cycle
          const prevBus = liveBuses.get(busId);
          if (prevBus) {
            tripMapCount = (bus.capacity || 50) - (prevBus.seatsAvailable || 50);
            eta = prevBus.eta;
          }
        }

        const payload = {
          busId,
          busName: bus.busName,
          lat,
          lng,
          speed,
          heading,
          routeId: bus.route,
          eta,
          seatsAvailable: (bus.capacity || 50) - tripMapCount,
          updatedAt,
        };

        liveBuses.set(busId, payload);
        io.to(`bus:${busId}`).emit('bus:update', payload);
      } catch (err) {
        console.error('driver:location error:', err.message);
      }
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id);
    });
  });
}

mongoose.connection.on('disconnected', () => {
  dbWarningShown = false;
});

module.exports = { initSocket, startBroadcast };
