const Trip = require('../models/Trip');
const Bus = require('../models/Bus');

const startTrip = async (req, res, next) => {
  try {
    const { busId, routeId } = req.body;
    const bus = await Bus.findById(busId);
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    if (bus.driver?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not assigned to this bus' });
    }
    const existing = await Trip.findOne({ bus: busId, status: 'ongoing' });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Trip already ongoing' });
    }
    const trip = await Trip.create({
      bus: busId,
      driver: req.user._id,
      route: routeId || bus.route,
      startTime: new Date(),
      status: 'ongoing',
    });
    bus.status = 'active';
    bus.isLive = true;
    await bus.save();
    res.status(201).json({ success: true, trip });
  } catch (err) {
    next(err);
  }
};

const endTrip = async (req, res, next) => {
  try {
    const trip = await Trip.findById(req.params.id);
    if (!trip) return res.status(404).json({ success: false, message: 'Trip not found' });
    if (trip.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not your trip' });
    }
    trip.status = 'completed';
    trip.endTime = new Date();
    await trip.save();
    await Bus.findByIdAndUpdate(trip.bus, { status: 'idle', isLive: false });
    res.json({ success: true, trip });
  } catch (err) {
    next(err);
  }
};

const getActiveTrips = async (req, res, next) => {
  try {
    const trips = await Trip.find({ status: 'ongoing' })
      .populate('bus', 'busNumber busName currentLocation')
      .populate('driver', 'name phone')
      .populate('route', 'routeName routeNumber');
    res.json({ success: true, trips });
  } catch (err) {
    next(err);
  }
};

const getTripById = async (req, res, next) => {
  try {
    const trip = await Trip.findById(req.params.id)
      .populate('bus')
      .populate('driver', 'name phone')
      .populate('route');
    if (!trip) return res.status(404).json({ success: false, message: 'Trip not found' });
    res.json({ success: true, trip });
  } catch (err) {
    next(err);
  }
};

module.exports = { startTrip, endTrip, getActiveTrips, getTripById };
