const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../server'); // We need to export app from server.js
const User = require('../src/models/User');
const Bus = require('../src/models/Bus');
const Trip = require('../src/models/Trip');
const { predictEta } = require('../src/services/etaService');

let mongoServer;
let driverToken;
let driverId;
let busId;
let tripId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  await mongoose.connect(uri);

  // Setup test data
  const driver = await User.create({
    name: 'Test Driver',
    phone: '9999999999',
    password: 'password123', // Will be hashed in pre-save if we had one, wait, we hash in controller.
    role: 'driver',
  });
  
  // We need the raw token or to hit login API
  // Since we hash in controller, creating directly with User.create means password is 'password123'.
  // But wait, auth controller checks bcrypt.compare. Let's just create token manually.
  const jwt = require('jsonwebtoken');
  driverToken = jwt.sign({ id: driver._id }, process.env.JWT_SECRET || 'testsecret', { expiresIn: '1h' });
  driverId = driver._id;

  const bus = await Bus.create({
    busNumber: 'GJ-01-XX-0000',
    busName: 'Test Bus',
    driver: driverId,
    status: 'idle',
    capacity: 50
  });
  busId = bus._id;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('App Tests', () => {
  it('Health Check', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBeTruthy();
  });

  it('Start Trip', async () => {
    const res = await request(app)
      .post('/api/trips/start')
      .set('Authorization', `Bearer ${driverToken}`)
      .send({ busId });
    
    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBeTruthy();
    expect(res.body.trip).toBeDefined();
    expect(res.body.trip.status).toBe('ongoing');
    tripId = res.body.trip._id;
  });

  it('End Trip', async () => {
    const res = await request(app)
      .put(`/api/trips/${tripId}/end`)
      .set('Authorization', `Bearer ${driverToken}`);
      
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBeTruthy();
    expect(res.body.trip.status).toBe('completed');
  });

  it('ETA Fallback', async () => {
    // Math fallback test since ETA_SERVICE_URL will fail in test env
    const etaData = await predictEta({
      busLat: 22.1647, busLng: 71.6661,
      stopLat: 22.1800, stopLng: 71.6700,
      speed: 40, hour: 10
    });
    expect(etaData.source).toBe('math');
    expect(etaData.distanceKm).toBeGreaterThan(0);
    expect(etaData.etaMinutes).toBeGreaterThan(0);
  });
});
