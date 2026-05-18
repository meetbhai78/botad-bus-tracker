const express = require('express');
const { getAllRoutes, getRouteById, getBusesOnRoute, createRoute, updateRoute, deleteRoute } = require('../controllers/routeController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllRoutes);
router.get('/:id', getRouteById);
router.get('/:id/buses', getBusesOnRoute);

// Admin only routes
// Deprecated: Use /api/admin/routes for proper stop building logic
router.post('/', (req, res) => res.status(400).json({ success: false, message: 'Deprecated. Use POST /api/admin/routes' }));
router.put('/:id', (req, res) => res.status(400).json({ success: false, message: 'Deprecated. Use PUT /api/admin/routes/:id' }));
router.delete('/:id', deleteRoute); // Delete is still fine but also available at /api/admin/routes

module.exports = router;
