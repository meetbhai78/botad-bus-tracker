const Timetable = require('../models/Timetable');
const Route = require('../models/Route');

const getTimetables = async (req, res, next) => {
  try {
    const filter = { isActive: true };
    if (req.query.routeId) filter.route = req.query.routeId;
    const timetables = await Timetable.find(filter)
      .populate('route', 'routeNumber routeName')
      .populate('bus', 'busNumber busName')
      .sort('departureTime');
    res.json({ success: true, timetables });
  } catch (err) {
    next(err);
  }
};

const searchTimetable = async (req, res, next) => {
  try {
    const { from, to } = req.query;
    if (!from || !to) {
      return res.status(400).json({ success: false, message: 'from and to stop names required' });
    }
    const fromRx = new RegExp(from.trim(), 'i');
    const toRx = new RegExp(to.trim(), 'i');
    
    // Find all routes
    const allRoutes = await Route.find();
    
    // Filter routes where 'from' stop comes before 'to' stop
    const validRoutes = allRoutes.filter(r => {
      if (!r.stops) return false;
      const fromIndex = r.stops.findIndex(s => fromRx.test(s.name));
      const toIndex = r.stops.findIndex(s => toRx.test(s.name));
      return fromIndex !== -1 && toIndex !== -1 && fromIndex < toIndex;
    });

    const routeIds = validRoutes.map((r) => r._id);
    const timetables = await Timetable.find({ route: { $in: routeIds }, isActive: true })
      .populate('route', 'routeNumber routeName stops')
      .populate('bus', 'busNumber busName')
      .sort('departureTime');
    res.json({ success: true, routes: validRoutes, timetables });
  } catch (err) {
    next(err);
  }
};

const createTimetable = async (req, res, next) => {
  try {
    const data = { ...req.body, updatedAt: new Date() };
    const entry = await Timetable.create(data);
    const populated = await Timetable.findById(entry._id)
      .populate('route', 'routeNumber routeName')
      .populate('bus', 'busNumber busName');
    res.status(201).json({ success: true, timetable: populated });
  } catch (err) {
    next(err);
  }
};

const updateTimetable = async (req, res, next) => {
  try {
    const entry = await Timetable.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedAt: new Date() },
      { new: true }
    )
      .populate('route', 'routeNumber routeName')
      .populate('bus', 'busNumber busName');
    if (!entry) return res.status(404).json({ success: false, message: 'Timetable not found' });
    res.json({ success: true, timetable: entry });
  } catch (err) {
    next(err);
  }
};

const deleteTimetable = async (req, res, next) => {
  try {
    const entry = await Timetable.findByIdAndUpdate(
      req.params.id,
      { isActive: false, updatedAt: new Date() },
      { new: true }
    );
    if (!entry) return res.status(404).json({ success: false, message: 'Timetable not found' });
    res.json({ success: true, timetable: entry });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getTimetables,
  searchTimetable,
  createTimetable,
  updateTimetable,
  deleteTimetable,
};
