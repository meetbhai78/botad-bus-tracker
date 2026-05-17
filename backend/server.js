/**
 * Botad Bus Tracker — Main server
 * Express REST API + Socket.io real-time
 */
require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const connectDB = require('./src/config/db');
const errorHandler = require('./src/middleware/errorHandler');
const { initSocket, startBroadcast } = require('./src/socket');

const authRoutes = require('./src/routes/auth');
const busRoutes = require('./src/routes/buses');
const routeRoutes = require('./src/routes/routes');
const tripRoutes = require('./src/routes/trips');
const ticketRoutes = require('./src/routes/tickets');
const adminRoutes = require('./src/routes/admin');
const stopRoutes = require('./src/routes/stops');
const timetableRoutes = require('./src/routes/timetable');

const app = express();
const server = http.createServer(app);

const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000').split(',').map((s) => s.trim());

const io = new Server(server, {
  cors: { origin: corsOrigins, methods: ['GET', 'POST'] },
});

app.use(
  cors({
    origin: corsOrigins,
    credentials: true,
  })
);
app.use(express.json());

// Serve static admin files
const path = require('path');
app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (req, res) => {
  res.json({ success: true, service: 'Botad Bus Tracker API', city: 'Botad, Gujarat' });
});

app.use('/api/auth', authRoutes);
app.use('/api/buses', busRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/stops', stopRoutes);
app.use('/api/timetable', timetableRoutes);
app.use('/api/admin', adminRoutes);

app.use(errorHandler);

initSocket(io);

const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    startBroadcast(io);
    server.listen(PORT, () => {
      console.log(`Botad Bus Tracker API running on port ${PORT}`);
      console.log(`Health check: http://localhost:${PORT}/health`);
    });
  })
  .catch((err) => {
    console.error('\n*** MongoDB connection failed ***');
    console.error(err.message);
    console.error('\nFix one of these:');
    console.error('  1) Install MongoDB locally and start the service, OR');
    console.error('  2) Use MongoDB Atlas — set MONGODB_URI in backend/.env');
    console.error('     Example: mongodb+srv://user:pass@cluster.mongodb.net/botad-bus-tracker\n');
    process.exit(1);
  });
