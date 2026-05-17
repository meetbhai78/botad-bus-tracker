const express = require('express');
const {
  bookTicket,
  bookTicketSimple,
  getMyTickets,
  verifyTicket,
  cancelTicket,
} = require('../controllers/ticketController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.post('/book', protect, bookTicket);
router.post('/book-simple', protect, bookTicketSimple);
router.get('/my', protect, getMyTickets);
router.post('/verify', protect, authorize('driver'), verifyTicket);
router.put('/:id/cancel', protect, cancelTicket);

module.exports = router;
