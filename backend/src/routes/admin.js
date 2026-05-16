const express = require('express');
const {
  getDashboard,
  getAllBusesAdmin,
  getDrivers,
  createBus,
  updateBus,
  deleteBus,
  dailyReport,
  revenueReport,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/dashboard', getDashboard);
router.get('/buses', getAllBusesAdmin);
router.get('/drivers', getDrivers);
router.post('/buses', createBus);
router.put('/buses/:id', updateBus);
router.delete('/buses/:id', deleteBus);
router.get('/reports/daily', dailyReport);
router.get('/reports/revenue', revenueReport);

module.exports = router;
