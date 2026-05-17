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

const createRoute = async (req, res, next) => {
  try {
    const route = await Route.create(req.body);
    res.status(201).json({ success: true, route });
  } catch (err) {
    next(err);
  }
};

const updateRoute = async (req, res, next) => {
  try {
    const route = await Route.findByIdAndUpdate(req.params.id, req.body, { new: true });
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

module.exports = { getAllRoutes, getRouteById, getBusesOnRoute, createRoute, updateRoute, deleteRoute };
