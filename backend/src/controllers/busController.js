const Bus = require('../models/Bus');
const Trip = require('../models/Trip');
const { haversineKm, estimateEtaMinutes } = require('../utils/distance');

const getAllBuses = async (req, res, next) => {
  try {
    let buses = await Bus.find({ status: { $ne: 'maintenance' } })
      .populate('driver', 'name phone profilePhoto')
      .populate('route'); // Populate full route to access stops

    const { from, to } = req.query;
    if (from && to) {
      const fromQ = from.toLowerCase().trim();
      const toQ = to.toLowerCase().trim();
      buses = buses.filter((b) => {
        if (!b.route || !b.route.stops) return false;
        // Exact match (case-insensitive) to avoid substring false positives
        // e.g., "Botad" should NOT match "Old Botad" or "Botad Colony"
        const fromStop = b.route.stops.find(s => s.name.toLowerCase().trim() === fromQ);
        const toStop = b.route.stops.find(s => s.name.toLowerCase().trim() === toQ);
        return fromStop && toStop && fromStop.order < toStop.order;
      });
    }

    res.json({ success: true, buses });
  } catch (err) {
    next(err);
  }
};

const getBusById = async (req, res, next) => {
  try {
    const bus = await Bus.findById(req.params.id)
      .populate('driver', 'name phone')
      .populate('route');
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const getNearbyBuses = async (req, res, next) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'lat and lng required' });
    }
    const buses = await Bus.find({ isLive: true, 'currentLocation.lat': { $exists: true } })
      .populate('route', 'routeName routeNumber');
    const hour = new Date().getHours();
    const withDistance = buses
      .map((b) => {
        const dist = haversineKm(lat, lng, b.currentLocation.lat, b.currentLocation.lng);
        const eta = estimateEtaMinutes(dist, b.currentLocation.speed, hour);
        return { ...b.toObject(), distanceKm: Math.round(dist * 100) / 100, etaMinutes: eta };
      })
      .sort((a, b) => a.distanceKm - b.distanceKm);
    res.json({ success: true, buses: withDistance });
  } catch (err) {
    next(err);
  }
};

const updateLocation = async (req, res, next) => {
  try {
    const { lat, lng, speed, heading } = req.body;
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (bus.driver?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not your bus' });
    }
    bus.currentLocation = { lat, lng, speed, heading, updatedAt: new Date() };
    bus.isLive = true;
    bus.status = 'active';
    await bus.save();

    const trip = await Trip.findOne({ bus: bus._id, status: 'ongoing' });
    if (trip) {
      trip.locationHistory.push({ lat, lng, speed, timestamp: new Date() });
      await trip.save();
    }
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (req.user.role !== 'admin' && bus.driver?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not your bus' });
    }
    bus.status = req.body.status;
    bus.isLive = req.body.status === 'active';
    await bus.save();
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const assignBus = async (req, res, next) => {
  try {
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (bus.driver && bus.driver.toString() !== req.user._id.toString()) {
      return res.status(400).json({ success: false, message: 'Bus is already assigned to another driver' });
    }
    bus.driver = req.user._id;
    bus.status = 'active';
    await bus.save();
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const releaseBus = async (req, res, next) => {
  try {
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (bus.driver && bus.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'You are not assigned to this bus' });
    }
    bus.driver = null;
    bus.status = 'idle';
    bus.isLive = false;
    await bus.save();
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const getLocationHistory = async (req, res, next) => {
  try {
    const bus = await Bus.findById(req.params.id);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (req.user.role !== 'admin' && bus.driver?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not your bus' });
    }
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const trips = await Trip.find({
      bus: req.params.id,
      startTime: { $gte: start },
    }).select('locationHistory startTime endTime');
    res.json({ success: true, trips });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAllBuses,
  getBusById,
  getNearbyBuses,
  updateLocation,
  updateStatus,
  getLocationHistory,
  assignBus,
  releaseBus,
};
