const bcrypt = require('bcryptjs');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');

const register = async (req, res, next) => {
  try {
    const { name, phone, email, password, role } = req.body;
    const exists = await User.findOne({ phone });
    if (exists) {
      return res.status(400).json({ success: false, message: 'Phone already registered' });
    }
    const hashed = await bcrypt.hash(password, 12);
    if (role === 'admin' || role === 'driver') {
      return res.status(403).json({
        success: false,
        message: 'Passenger registration only. Drivers are added by admin.',
      });
    }
    const user = await User.create({
      name,
      phone,
      email,
      password: hashed,
      role: 'passenger',
    });
    res.status(201).json({
      success: true,
      token: generateToken(user._id),
      user: { id: user._id, name: user.name, phone: user.phone, role: user.role },
    });
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ phone });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    res.json({
      success: true,
      token: generateToken(user._id),
      user: { id: user._id, name: user.name, phone: user.phone, role: user.role },
    });
  } catch (err) {
    next(err);
  }
};

const driverLogin = async (req, res, next) => {
  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ phone, role: 'driver' });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ success: false, message: 'Invalid driver credentials' });
    }
    res.json({
      success: true,
      token: generateToken(user._id),
      user: { id: user._id, name: user.name, phone: user.phone, role: user.role },
    });
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res) => {
  res.json({ success: true, user: req.user });
};

const refreshToken = async (req, res) => {
  res.json({ success: true, token: generateToken(req.user._id) });
};

module.exports = { register, login, driverLogin, getMe, refreshToken };
