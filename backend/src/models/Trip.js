const mongoose = require('mongoose');

const TripSchema = new mongoose.Schema({
  bus: { type: mongoose.Schema.Types.ObjectId, ref: 'Bus' },
  driver: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  route: { type: mongoose.Schema.Types.ObjectId, ref: 'Route' },
  startTime: Date,
  endTime: Date,
  passengersCount: { type: Number, default: 0 },
  locationHistory: [
    {
      lat: Number,
      lng: Number,
      timestamp: Date,
      speed: Number,
    },
  ],
  status: {
    type: String,
    enum: ['scheduled', 'ongoing', 'completed'],
    default: 'scheduled',
  },
});

module.exports = mongoose.model('Trip', TripSchema);
