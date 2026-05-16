/**
 * Botad seed data — routes, admin, sample driver & bus
 * Run: npm run seed (from backend folder, with .env set)
 */
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const connectDB = require('../config/db');
const User = require('../models/User');
const Route = require('../models/Route');
const Bus = require('../models/Bus');

const botadStops = [
  { name: 'Botad Bus Stand', lat: 22.1647, lng: 71.6661 },
  { name: 'Botad Hospital', lat: 22.1689, lng: 71.6698 },
  { name: 'Botad Market', lat: 22.1712, lng: 71.672 },
  { name: 'Gandhi Chowk', lat: 22.1658, lng: 71.664 },
  { name: 'Railway Station', lat: 22.158, lng: 71.659 },
  { name: 'Botad College', lat: 22.175, lng: 71.675 },
  { name: 'Government School', lat: 22.163, lng: 71.668 },
  { name: 'Sadar Bazaar', lat: 22.17, lng: 71.671 },
];

const routeDefs = [
  {
    routeNumber: 'Route 1',
    routeName: 'Bus Stand to College',
    stopNames: ['Botad Bus Stand', 'Botad Hospital', 'Botad Market', 'Gandhi Chowk', 'Botad College'],
  },
  {
    routeNumber: 'Route 2',
    routeName: 'Railway to Bus Stand',
    stopNames: ['Railway Station', 'Government School', 'Sadar Bazaar', 'Botad Bus Stand'],
  },
  {
    routeNumber: 'Route 3',
    routeName: 'College to Railway',
    stopNames: ['Botad College', 'Botad Market', 'Botad Hospital', 'Railway Station'],
  },
];

async function seed() {
  await connectDB();

  await User.deleteMany({});
  await Route.deleteMany({});
  await Bus.deleteMany({});

  const adminPass = await bcrypt.hash('admin123', 12);
  const driverPass = await bcrypt.hash('driver123', 12);

  const admin = await User.create({
    name: 'Botad Admin',
    phone: '9999999999',
    password: adminPass,
    role: 'admin',
    email: 'admin@botadbus.local',
  });

  const driver = await User.create({
    name: 'Demo Driver',
    phone: '9876543210',
    password: driverPass,
    role: 'driver',
  });

  const stopMap = Object.fromEntries(botadStops.map((s) => [s.name, s]));

  const routes = [];
  for (const def of routeDefs) {
    const stops = def.stopNames.map((name, i) => ({
      name,
      lat: stopMap[name].lat,
      lng: stopMap[name].lng,
      order: i + 1,
      estimatedTime: i * 8,
    }));
    routes.push(
      await Route.create({
        routeNumber: def.routeNumber,
        routeName: def.routeName,
        stops,
        totalDistance: stops.length * 1.2,
        totalTime: stops.length * 8,
      })
    );
  }

  await Bus.create({
    busNumber: 'GJ-11-T-2847',
    busName: 'B1',
    capacity: 50,
    driver: driver._id,
    route: routes[0]._id,
    status: 'idle',
    currentLocation: { lat: 22.1647, lng: 71.6661, updatedAt: new Date() },
  });

  console.log('Seed complete!');
  console.log('Admin: phone 9999999999 / password admin123');
  console.log('Driver: phone 9876543210 / password driver123');
  console.log('Admin id:', admin._id.toString());

  await mongoose.disconnect();
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
