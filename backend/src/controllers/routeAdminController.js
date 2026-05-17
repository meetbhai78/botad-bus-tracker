const Route = require('../models/Route');
const Stop = require('../models/Stop');

const buildStopsFromBody = async (stopItems) => {
  if (!Array.isArray(stopItems) || !stopItems.length) return [];
  const built = [];
  for (let i = 0; i < stopItems.length; i++) {
    const item = stopItems[i];
    let name = item.name;
    let lat = item.lat;
    let lng = item.lng;
    if (item.stopId) {
      const stop = await Stop.findById(item.stopId);
      if (stop) {
        name = stop.name;
        lat = stop.lat;
        lng = stop.lng;
      }
    }
    built.push({
      name,
      lat,
      lng,
      order: item.order ?? i + 1,
      estimatedTime: item.estimatedTime ?? i * 8,
    });
  }
  return built;
};

const createRoute = async (req, res, next) => {
  try {
    const stops = await buildStopsFromBody(req.body.stops);
    const route = await Route.create({
      routeNumber: req.body.routeNumber,
      routeName: req.body.routeName,
      stops,
      totalDistance: req.body.totalDistance ?? stops.length * 1.2,
      totalTime: req.body.totalTime ?? stops.length * 8,
    });
    res.status(201).json({ success: true, route });
  } catch (err) {
    next(err);
  }
};

const updateRoute = async (req, res, next) => {
  try {
    const updates = { ...req.body };
    if (req.body.stops) {
      updates.stops = await buildStopsFromBody(req.body.stops);
    }
    const route = await Route.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!route) return res.status(404).json({ success: false, message: 'Route not found' });
    res.json({ success: true, route });
  } catch (err) {
    next(err);
  }
};

const deleteRoute = async (req, res, next) => {
  try {
    await Route.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Route deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = { createRoute, updateRoute, deleteRoute };
