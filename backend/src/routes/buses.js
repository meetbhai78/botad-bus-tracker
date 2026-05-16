const express = require('express');
const {
  getAllBuses,
  getBusById,
  getNearbyBuses,
  updateLocation,
  updateStatus,
  getLocationHistory,
} = require('../controllers/busController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllBuses);
router.get('/nearby', getNearbyBuses);
router.get('/:id', getBusById);
router.get('/:id/history', getLocationHistory);
router.put('/:id/location', protect, authorize('driver', 'admin'), updateLocation);
router.put('/:id/status', protect, authorize('driver', 'admin'), updateStatus);

module.exports = router;
