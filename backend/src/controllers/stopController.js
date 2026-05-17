const Stop = require('../models/Stop');

const getStops = async (req, res, next) => {
  try {
    const query = req.query.all === '1' ? {} : { isActive: true };
    const stops = await Stop.find(query).sort('name');
    res.json({ success: true, stops });
  } catch (err) {
    next(err);
  }
};

const getStopById = async (req, res, next) => {
  try {
    const stop = await Stop.findById(req.params.id);
    if (!stop) return res.status(404).json({ success: false, message: 'Stop not found' });
    res.json({ success: true, stop });
  } catch (err) {
    next(err);
  }
};

const createStop = async (req, res, next) => {
  try {
    const stop = await Stop.create(req.body);
    res.status(201).json({ success: true, stop });
  } catch (err) {
    next(err);
  }
};

const updateStop = async (req, res, next) => {
  try {
    const stop = await Stop.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!stop) return res.status(404).json({ success: false, message: 'Stop not found' });
    res.json({ success: true, stop });
  } catch (err) {
    next(err);
  }
};

const deleteStop = async (req, res, next) => {
  try {
    const stop = await Stop.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
    if (!stop) return res.status(404).json({ success: false, message: 'Stop not found' });
    res.json({ success: true, stop });
  } catch (err) {
    next(err);
  }
};

module.exports = { getStops, getStopById, createStop, updateStop, deleteStop };
