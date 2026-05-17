const express = require('express');
const { getAllRoutes, getRouteById, getBusesOnRoute, createRoute, updateRoute, deleteRoute } = require('../controllers/routeController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllRoutes);
router.get('/:id', getRouteById);
router.get('/:id/buses', getBusesOnRoute);

// Admin only routes
router.use(protect, authorize('admin'));
router.post('/', createRoute);
router.put('/:id', updateRoute);
router.delete('/:id', deleteRoute);

module.exports = router;
