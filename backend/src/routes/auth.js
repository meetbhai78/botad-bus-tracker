const express = require('express');
const { body } = require('express-validator');
const rateLimit = require('express-rate-limit');
const { register, login, driverLogin, getMe, refreshToken } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

const router = express.Router();

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { success: false, message: 'Too many attempts, try again later' },
});

const validate = (req, res, next) => {
  const { validationResult } = require('express-validator');
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

router.post(
  '/register',
  authLimiter,
  [
    body('name').trim().notEmpty(),
    body('phone').trim().notEmpty(),
    body('password').isLength({ min: 6 }),
  ],
  validate,
  register
);
router.post('/login', authLimiter, [body('phone').notEmpty(), body('password').notEmpty()], validate, login);
router.post('/driver/login', authLimiter, [body('phone').notEmpty(), body('password').notEmpty()], validate, driverLogin);
router.get('/me', protect, getMe);
router.post('/refresh-token', protect, refreshToken);

module.exports = router;
