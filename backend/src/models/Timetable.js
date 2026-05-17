const mongoose = require('mongoose');

const TimetableSchema = new mongoose.Schema({
  route: { type: mongoose.Schema.Types.ObjectId, ref: 'Route', required: true },
  bus: { type: mongoose.Schema.Types.ObjectId, ref: 'Bus' },
  label: { type: String, trim: true },
  departureTime: { type: String, required: true },
  direction: String,
  isActive: { type: Boolean, default: true },
  schedule: [
    {
      stop: { type: mongoose.Schema.Types.ObjectId, ref: 'Stop' },
      stopName: String,
      arrivalTime: String,
      order: Number,
    },
  ],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Timetable', TimetableSchema);
