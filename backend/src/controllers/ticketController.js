const mongoose = require('mongoose');
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
    const ticket = await Ticket.create({
      passenger: req.user._id,
      trip: tripId,
      fromStop,
      toStop,
      price: TICKET_PRICE,
      qrCode: '',
      expiresAt,
    });
    const payload = JSON.stringify({
      ticketId: ticket._id.toString(),
      passengerId: req.user._id.toString(),
      tripId: tripId.toString(),
      fromStop,
      toStop,
      expiresAt: expiresAt.toISOString(),
    });
    ticket.qrCode = await QRCode.toDataURL(payload);
    await ticket.save();
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
    const { ticketId, qrCode } = req.body;

    if (!ticketId && (qrCode == null || !String(qrCode).trim())) {
      return res.status(400).json({ success: false, message: 'ticketId or qrCode required' });
    }

    let ticket = null;
    if (ticketId && mongoose.Types.ObjectId.isValid(String(ticketId))) {
      ticket = await Ticket.findById(ticketId);
    } else if (qrCode != null && String(qrCode).trim()) {
      const raw = String(qrCode).trim();
      try {
        const parsed = JSON.parse(raw);
        if (parsed.ticketId && mongoose.Types.ObjectId.isValid(String(parsed.ticketId))) {
          ticket = await Ticket.findById(parsed.ticketId);
        }
      } catch {
        /* not JSON */
      }
      if (!ticket && mongoose.Types.ObjectId.isValid(raw) && raw.length === 24) {
        ticket = await Ticket.findById(raw);
      }
      if (!ticket) {
        ticket = await Ticket.findOne({ qrCode: raw });
      }
    }

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

const bookTicketSimple = async (req, res, next) => {
  try {
    const { fromStop, toStop, price } = req.body;
    const expiresAt = new Date(Date.now() + QR_EXPIRE_HOURS * 60 * 60 * 1000);
    const ticket = await Ticket.create({
      passenger: req.user._id,
      fromStop,
      toStop,
      price: price || TICKET_PRICE,
      qrCode: '',
      expiresAt,
    });
    const payload = JSON.stringify({
      ticketId: ticket._id.toString(),
      passengerId: req.user._id.toString(),
      fromStop,
      toStop,
      expiresAt: expiresAt.toISOString(),
    });
    ticket.qrCode = payload;
    await ticket.save();
    res.status(201).json({
      success: true,
      ticket,
      data: { qrCode: payload, ticketId: ticket._id },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { bookTicket, bookTicketSimple, getMyTickets, verifyTicket, cancelTicket };
