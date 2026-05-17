const express = require('express');
const { getTimetables, searchTimetable } = require('../controllers/timetableController');

const router = express.Router();

router.get('/', getTimetables);
router.get('/search', searchTimetable);

module.exports = router;
