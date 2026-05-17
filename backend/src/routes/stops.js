const express = require('express');
const { getStops, getStopById } = require('../controllers/stopController');

const router = express.Router();

router.get('/', getStops);
router.get('/:id', getStopById);

module.exports = router;
