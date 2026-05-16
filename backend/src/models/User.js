const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  email: String,
  password: { type: String, required: true },
  role: {
    type: String,
    enum: ['passenger', 'driver', 'admin'],
    default: 'passenger',
  },
  fcmToken: String,
  profilePhoto: String,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', UserSchema);
