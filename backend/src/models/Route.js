const mongoose = require('mongoose');

const RouteSchema = new mongoose.Schema({
  routeNumber: String,
  routeName: String,
  stops: [
    {
      name: String,
      lat: Number,
      lng: Number,
      order: Number,
      estimatedTime: Number,
    },
  ],
  totalDistance: Number,
  totalTime: Number,
  polyline: String, // Encoded OSRM polyline for map drawing
});

module.exports = mongoose.model('Route', RouteSchema);
