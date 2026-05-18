const express = require('express');
const { startTrip, endTrip, getActiveTrips, getTripById } = require('../controllers/tripController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/active', protect, getActiveTrips);
router.get('/:id', protect, getTripById);
router.post('/start', protect, authorize('driver'), startTrip);
router.put('/:id/end', protect, authorize('driver'), endTrip);

module.exports = router;
