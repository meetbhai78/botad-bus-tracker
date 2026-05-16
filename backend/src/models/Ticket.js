const mongoose = require('mongoose');

const TicketSchema = new mongoose.Schema({
  passenger: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  trip: { type: mongoose.Schema.Types.ObjectId, ref: 'Trip' },
  fromStop: String,
  toStop: String,
  price: Number,
  qrCode: String,
  status: {
    type: String,
    enum: ['active', 'used', 'cancelled'],
    default: 'active',
  },
  bookedAt: { type: Date, default: Date.now },
  expiresAt: { type: Date },
});

module.exports = mongoose.model('Ticket', TicketSchema);
