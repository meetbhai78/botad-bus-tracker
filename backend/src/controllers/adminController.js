const bcrypt = require('bcryptjs');
const Bus = require('../models/Bus');
const User = require('../models/User');
const Trip = require('../models/Trip');
const Ticket = require('../models/Ticket');
const Route = require('../models/Route');

const getDashboard = async (req, res, next) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const [activeBuses, drivers, routes, todayTrips, todayTickets] = await Promise.all([
      Bus.countDocuments({ isLive: true }),
      User.countDocuments({ role: 'driver' }),
      Route.countDocuments(),
      Trip.countDocuments({ startTime: { $gte: start } }),
      Ticket.find({ bookedAt: { $gte: start }, status: { $ne: 'cancelled' } }),
    ]);
    const revenue = todayTickets.reduce((s, t) => s + (t.price || 0), 0);
    const passengersToday = todayTickets.length;
    res.json({
      success: true,
      stats: {
        activeBuses,
        drivers,
        routes,
        todayTrips,
        passengersToday,
        revenue,
      },
    });
  } catch (err) {
    next(err);
  }
};

const getAllBusesAdmin = async (req, res, next) => {
  try {
    const buses = await Bus.find()
      .populate('driver', 'name phone')
      .populate('route', 'routeName routeNumber');
    res.json({ success: true, buses });
  } catch (err) {
    next(err);
  }
};

const getDrivers = async (req, res, next) => {
  try {
    const drivers = await User.find({ role: 'driver' }).select('-password');
    res.json({ success: true, drivers });
  } catch (err) {
    next(err);
  }
};

const createBus = async (req, res, next) => {
  try {
    const bus = await Bus.create(req.body);
    res.status(201).json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const updateBus = async (req, res, next) => {
  try {
    const bus = await Bus.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!bus) return res.status(404).json({ success: false, message: 'Bus not found' });
    res.json({ success: true, bus });
  } catch (err) {
    next(err);
  }
};

const deleteBus = async (req, res, next) => {
  try {
    await Bus.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Bus deleted' });
  } catch (err) {
    next(err);
  }
};

const dailyReport = async (req, res, next) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const trips = await Trip.find({ startTime: { $gte: start } }).populate('bus', 'busNumber');
    const tickets = await Ticket.find({ bookedAt: { $gte: start } });
    res.json({
      success: true,
      report: {
        date: start,
        tripsCount: trips.length,
        ticketsCount: tickets.length,
        revenue: tickets.reduce((s, t) => s + (t.price || 0), 0),
        trips,
      },
    });
  } catch (err) {
    next(err);
  }
};

const revenueReport = async (req, res, next) => {
  try {
    const days = parseInt(req.query.days, 10) || 7;
    const start = new Date();
    start.setDate(start.getDate() - days);
    const tickets = await Ticket.find({
      bookedAt: { $gte: start },
      status: { $ne: 'cancelled' },
    });
    const byDay = {};
    tickets.forEach((t) => {
      const key = t.bookedAt.toISOString().slice(0, 10);
      byDay[key] = (byDay[key] || 0) + (t.price || 0);
    });
    res.json({ success: true, byDay, total: tickets.reduce((s, t) => s + (t.price || 0), 0) });
  } catch (err) {
    next(err);
  }
};

const getPassengers = async (req, res, next) => {
  try {
    const passengers = await User.find({ role: 'passenger' })
      .select('-password')
      .sort('-createdAt');
    res.json({ success: true, passengers });
  } catch (err) {
    next(err);
  }
};

const createDriver = async (req, res, next) => {
  try {
    const { name, phone, email, password } = req.body;
    const exists = await User.findOne({ phone });
    if (exists) {
      return res.status(400).json({ success: false, message: 'Phone already registered' });
    }
    const hashed = await bcrypt.hash(password || 'driver123', 12);
    const driver = await User.create({
      name,
      phone,
      email,
      password: hashed,
      role: 'driver',
    });
    res.status(201).json({
      success: true,
      driver: { id: driver._id, name: driver.name, phone: driver.phone, role: driver.role },
    });
  } catch (err) {
    next(err);
  }
};

const getAllRoutesAdmin = async (req, res, next) => {
  try {
    const routes = await Route.find().sort('routeNumber');
    res.json({ success: true, routes });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getDashboard,
  getAllBusesAdmin,
  getDrivers,
  getPassengers,
  createDriver,
  getAllRoutesAdmin,
  createBus,
  updateBus,
  deleteBus,
  dailyReport,
  revenueReport,
};
