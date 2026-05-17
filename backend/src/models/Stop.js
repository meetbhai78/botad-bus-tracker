const mongoose = require('mongoose');

const StopSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  lat: { type: Number, required: true },
  lng: { type: Number, required: true },
  address: String,
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
});

StopSchema.index({ name: 1 });

module.exports = mongoose.model('Stop', StopSchema);
