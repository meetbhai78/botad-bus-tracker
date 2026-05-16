const QRCode = require('qrcode');
const Ticket = require('../models/Ticket');
const Trip = require('../models/Trip');

const TICKET_PRICE = 15;
const QR_EXPIRE_HOURS = 24;

const bookTicket = async (req, res, next) => {
  try {
    const { tripId, fromStop, toStop } = req.body;
    const trip = await Trip.findById(tripId);
    if (!trip || trip.status !== 'ongoing') {
      return res.status(400).json({ success: false, message: 'No active trip' });
    }
    const expiresAt = new Date(Date.now() + QR_EXPIRE_HOURS * 60 * 60 * 1000);
    const payload = JSON.stringify({
      passengerId: req.user._id,
      tripId,
      fromStop,
      toStop,
      expiresAt,
    });
    const qrCode = await QRCode.toDataURL(payload);
    const ticket = await Ticket.create({
      passenger: req.user._id,
      trip: tripId,
      fromStop,
      toStop,
      price: TICKET_PRICE,
      qrCode,
      expiresAt,
    });
    trip.passengersCount += 1;
    await trip.save();
    res.status(201).json({ success: true, ticket });
  } catch (err) {
    next(err);
  }
};

const getMyTickets = async (req, res, next) => {
  try {
    const tickets = await Ticket.find({ passenger: req.user._id })
      .populate('trip')
      .sort('-bookedAt');
    res.json({ success: true, tickets });
  } catch (err) {
    next(err);
  }
};

const verifyTicket = async (req, res, next) => {
  try {
    const { ticketId } = req.body;
    const ticket = await Ticket.findById(ticketId);
    if (!ticket) return res.status(404).json({ success: false, message: 'Ticket not found' });
    if (ticket.status !== 'active') {
      return res.status(400).json({ success: false, message: `Ticket ${ticket.status}` });
    }
    if (ticket.expiresAt && ticket.expiresAt < new Date()) {
      ticket.status = 'cancelled';
      await ticket.save();
      return res.status(400).json({ success: false, message: 'QR expired' });
    }
    ticket.status = 'used';
    await ticket.save();
    res.json({ success: true, message: 'Verified', ticket });
  } catch (err) {
    next(err);
  }
};

const cancelTicket = async (req, res, next) => {
  try {
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) return res.status(404).json({ success: false, message: 'Ticket not found' });
    if (ticket.passenger.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not your ticket' });
    }
    ticket.status = 'cancelled';
    await ticket.save();
    res.json({ success: true, ticket });
  } catch (err) {
    next(err);
  }
};

module.exports = { bookTicket, getMyTickets, verifyTicket, cancelTicket };
