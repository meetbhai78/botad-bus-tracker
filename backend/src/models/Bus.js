const mongoose = require('mongoose');

const BusSchema = new mongoose.Schema({
  busNumber: { type: String, required: true, unique: true },
  busName: String,
  capacity: { type: Number, default: 50 },
  driver: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  route: { type: mongoose.Schema.Types.ObjectId, ref: 'Route' },
  currentLocation: {
    lat: Number,
    lng: Number,
    speed: Number,
    heading: Number,
    updatedAt: Date,
  },
  status: {
    type: String,
    enum: ['active', 'idle', 'maintenance'],
    default: 'idle',
  },
  isLive: { type: Boolean, default: false },
});

module.exports = mongoose.model('Bus', BusSchema);
