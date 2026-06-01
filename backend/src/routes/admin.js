const express = require('express');
const {
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
} = require('../controllers/adminController');
const { createStop, updateStop, deleteStop } = require('../controllers/stopController');
const { createRoute, updateRoute, deleteRoute } = require('../controllers/routeAdminController');
const {
  createTimetable,
  updateTimetable,
  deleteTimetable,
  getTimetables,
} = require('../controllers/timetableController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/dashboard', getDashboard);
router.get('/buses', getAllBusesAdmin);
router.post('/buses', createBus);
router.put('/buses/:id', updateBus);
router.delete('/buses/:id', deleteBus);

router.get('/drivers', getDrivers);
router.post('/drivers', createDriver);
router.get('/passengers', getPassengers);

router.get('/routes', getAllRoutesAdmin);
router.post('/routes', createRoute);
router.put('/routes/:id', updateRoute);
router.delete('/routes/:id', deleteRoute);

router.get('/stops', (req, res, next) => {
  req.query.all = '1';
  return require('../controllers/stopController').getStops(req, res, next);
});
router.post('/stops', createStop);
router.put('/stops/:id', updateStop);
router.delete('/stops/:id', deleteStop);

router.get('/timetable', (req, res, next) => {
  req.query.all = '1';
  next();
}, async (req, res, next) => {
  try {
    const Timetable = require('../models/Timetable');
    const timetables = await Timetable.find()
      .populate('route', 'routeNumber routeName')
      .populate('bus', 'busNumber busName')
      .sort('departureTime');
    res.json({ success: true, timetables });
  } catch (err) {
    next(err);
  }
});
router.post('/timetable', createTimetable);
router.put('/timetable/:id', updateTimetable);
router.delete('/timetable/:id', deleteTimetable);

router.get('/reports/daily', dailyReport);
router.get('/reports/revenue', revenueReport);

router.get('/emergency-alert', async (req, res, next) => {
  try {
    const Config = require('../models/Config');
    let alertConfig = await Config.findOne({ key: 'emergency_alert' });
    if (!alertConfig) {
      alertConfig = {
        key: 'emergency_alert',
        value: {
          active: process.env.EMERGENCY_ALERT_ACTIVE === 'true',
          message: process.env.EMERGENCY_ALERT_MESSAGE || 'All routes operating normally. Safe travels!',
          updatedAt: process.env.EMERGENCY_ALERT_TIME || new Date().toISOString()
        }
      };
    }
    res.json({ success: true, alert: alertConfig.value });
  } catch (err) {
    next(err);
  }
});

router.post('/emergency-alert', async (req, res, next) => {
  try {
    const Config = require('../models/Config');
    const { active, message } = req.body;
    
    const alertValue = {
      active: active === true,
      message: message || '',
      updatedAt: new Date().toISOString()
    };
    
    const alertConfig = await Config.findOneAndUpdate(
      { key: 'emergency_alert' },
      { value: alertValue },
      { new: true, upsert: true }
    );
    
    res.json({ success: true, alert: alertConfig.value });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
