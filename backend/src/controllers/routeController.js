const Route = require('../models/Route');
const Bus = require('../models/Bus');

const getAllRoutes = async (req, res, next) => {
  try {
    const routes = await Route.find().sort('routeNumber');
    res.json({ success: true, routes });
  } catch (err) {
    next(err);
  }
};

const getRouteById = async (req, res, next) => {
  try {
    const route = await Route.findById(req.params.id);
    if (!route) return res.status(404).json({ success: false, message: 'Route not found' });
    res.json({ success: true, route });
  } catch (err) {
    next(err);
  }
};

const getBusesOnRoute = async (req, res, next) => {
  try {
    const buses = await Bus.find({ route: req.params.id, isLive: true })
      .populate('driver', 'name phone');
    res.json({ success: true, buses });
  } catch (err) {
    next(err);
  }
};

module.exports = { getAllRoutes, getRouteById, getBusesOnRoute };
