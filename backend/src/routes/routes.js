const express = require('express');
const { getAllRoutes, getRouteById, getBusesOnRoute } = require('../controllers/routeController');

const router = express.Router();

router.get('/', getAllRoutes);
router.get('/:id', getRouteById);
router.get('/:id/buses', getBusesOnRoute);

module.exports = router;
