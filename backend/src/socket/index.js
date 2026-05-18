const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');
const Bus = require('../models/Bus');
const Trip = require('../models/Trip');
const { isDbReady } = require('../config/db');
const { haversineKm, estimateEtaMinutes } = require('../utils/distance');

const liveBuses = new Map();
let broadcastInterval = null;
let dbWarningShown = false;

function startBroadcast(io) {
  if (broadcastInterval) return;

  broadcastInterval = setInterval(async () => {
    if (!isDbReady()) {
      if (!dbWarningShown) {
        console.warn(
          'MongoDB not connected — live bus broadcast paused. Start MongoDB or set MONGODB_URI to Atlas.'
        );
        dbWarningShown = true;
      }
      return;
    }
    dbWarningShown = false;

    try {
      const buses = await Bus.find({ isLive: true }).populate('route', 'routeNumber');
      const trips = await Trip.find({ status: 'ongoing', bus: { $in: buses.map((b) => b._id) } });
      const tripMap = {};
      trips.forEach((t) => tripMap[t.bus.toString()] = t.passengersCount || 0);

      const list = buses.map((b) => ({
        busId: b._id,
        busName: b.busName || b.busNumber,
        lat: b.currentLocation?.lat,
        lng: b.currentLocation?.lng,
        speed: b.currentLocation?.speed,
        heading: b.currentLocation?.heading,
        routeId: b.route?._id,
        routeNumber: b.route?.routeNumber,
        eta: liveBuses.get(b._id.toString())?.eta,
        seatsAvailable: (b.capacity || 50) - (tripMap[b._id.toString()] || 0),
      }));
      io.emit('buses:locations', list);
    } catch (err) {
      if (!dbWarningShown) {
        console.error('Broadcast error:', err.message);
        dbWarningShown = true;
      }
    }
  }, 3000);
}

function initSocket(io) {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (token && isDbReady()) {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.user = await User.findById(decoded.id).select('-password');
      }
      next();
    } catch {
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

        const updatedAt = new Date();
        bus.currentLocation = { lat, lng, speed, heading, updatedAt };
        bus.isLive = true;
        bus.status = 'active';
        await bus.save();

        let tripMapCount = 0;
        if (tripId) {
          const trip = await Trip.findByIdAndUpdate(tripId, {
            $push: { locationHistory: { lat, lng, speed, timestamp: updatedAt } },
          });
          tripMapCount = trip?.passengersCount || 0;
        }

        let eta = null;
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
