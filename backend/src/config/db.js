const mongoose = require('mongoose');

/** MongoDB — local (27017) ya Atlas URI (.env) */
const connectDB = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not set in backend/.env');
  }

  mongoose.set('bufferCommands', false);

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 8000,
  });

  await mongoose.connection.db.admin().ping();
  console.log('MongoDB connected:', mongoose.connection.host);
};

const isDbReady = () => mongoose.connection.readyState === 1;

module.exports = connectDB;
module.exports.isDbReady = isDbReady;
