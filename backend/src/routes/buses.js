const express = require('express');
const {
  getAllBuses,
  getBusById,
  getNearbyBuses,
  updateLocation,
  updateStatus,
  getLocationHistory,
  assignBus,
  releaseBus
} = require('../controllers/busController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllBuses);
router.get('/nearby', getNearbyBuses);
router.get('/:id', getBusById);
router.get('/:id/history', protect, authorize('driver', 'admin'), getLocationHistory);
router.put('/:id/location', protect, authorize('driver', 'admin'), updateLocation);
router.put('/:id/status', protect, authorize('driver', 'admin'), updateStatus);
router.post('/:id/assign', protect, authorize('driver', 'admin'), assignBus);
router.post('/:id/release', protect, authorize('driver', 'admin'), releaseBus);

module.exports = router;
