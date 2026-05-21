/**
 * Botad seed data — stops, routes, timetable, admin, driver & bus
 * Run: npm run seed (from backend folder, with .env set)
 */
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const connectDB = require('../config/db');
const User = require('../models/User');
const Stop = require('../models/Stop');
const Route = require('../models/Route');
const Bus = require('../models/Bus');
const Timetable = require('../models/Timetable');

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
    routeNumber: 'R1',
    routeName: 'Bus Stand → College',
    stopNames: ['Botad Bus Stand', 'Botad Hospital', 'Botad Market', 'Gandhi Chowk', 'Botad College'],
  },
  {
    routeNumber: 'R2',
    routeName: 'Railway → Bus Stand',
    stopNames: ['Railway Station', 'Government School', 'Sadar Bazaar', 'Botad Bus Stand'],
  },
  {
    routeNumber: 'R3',
    routeName: 'College → Railway',
    stopNames: ['Botad College', 'Botad Market', 'Botad Hospital', 'Railway Station'],
  },
];

async function seed() {
  await connectDB();

  await User.deleteMany({});
  await Stop.deleteMany({});
  await Route.deleteMany({});
  await Bus.deleteMany({});
  await Timetable.deleteMany({});

  const adminPass = await bcrypt.hash('BeMeet@2007', 12);
  const driverPass = await bcrypt.hash('driver123', 12);
  const passengerPass = await bcrypt.hash('pass123', 12);

  await User.create({
    name: 'Botad Admin',
    phone: '7990431779',
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

  await User.create({
    name: 'Demo Passenger',
    phone: '9123456789',
    password: passengerPass,
    role: 'passenger',
    email: 'passenger@demo.local',
  });

  const stopDocs = {};
  for (const s of botadStops) {
    stopDocs[s.name] = await Stop.create(s);
  }

  const routes = [];
  for (const def of routeDefs) {
    const stops = def.stopNames.map((name, i) => ({
      name,
      lat: stopDocs[name].lat,
      lng: stopDocs[name].lng,
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

  const bus = await Bus.create({
    busNumber: 'GJ-11-T-2847',
    busName: 'B1',
    capacity: 50,
    driver: driver._id,
    route: routes[0]._id,
    status: 'idle',
    currentLocation: { lat: 22.1647, lng: 71.6661, updatedAt: new Date() },
  });

  const departures = ['07:00', '09:30', '12:00', '17:30'];
  for (const time of departures) {
    await Timetable.create({
      route: routes[0]._id,
      bus: bus._id,
      label: `Morning service ${time}`,
      departureTime: time,
      direction: 'Bus Stand to College',
      schedule: routes[0].stops.map((s, i) => ({
        stop: stopDocs[s.name]._id,
        stopName: s.name,
        arrivalTime: addMinutes(time, i * 8),
        order: i + 1,
      })),
    });
  }

  console.log('Seed complete!');
  console.log('Admin:    phone 7990431779 / BeMeet@2007');
  console.log('Driver:   phone 9876543210 / driver123');
  console.log('Passenger: phone 9123456789 / pass123');

  await mongoose.disconnect();
}

function addMinutes(hhmm, mins) {
  const [h, m] = hhmm.split(':').map(Number);
  const total = h * 60 + m + mins;
  const nh = Math.floor(total / 60) % 24;
  const nm = total % 60;
  return `${String(nh).padStart(2, '0')}:${String(nm).padStart(2, '0')}`;
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
