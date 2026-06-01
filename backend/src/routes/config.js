const express = require('express');
const Config = require('../models/Config');
const router = express.Router();

router.get('/app-version', (req, res) => {
  res.json({
    success: true,
    latestVersion: process.env.APP_LATEST_VERSION || '1.0.0',
    latestBuildNumber: parseInt(process.env.APP_LATEST_BUILD || '1', 10),
    mandatoryUpdate: process.env.APP_MANDATORY_UPDATE === 'true',
    updateMessage: process.env.APP_UPDATE_MESSAGE || 'A new awesome version of Botad-ct is available! Please update to continue enjoying the best experience.',
    updateUrl: process.env.APP_UPDATE_URL || 'https://botad-bus-tracker.onrender.com'
  });
});

router.get('/emergency-alert', async (req, res) => {
  try {
    const alertConfig = await Config.findOne({ key: 'emergency_alert' });
    if (alertConfig && alertConfig.value) {
      return res.json({
        success: true,
        active: alertConfig.value.active === true,
        message: alertConfig.value.message || 'All routes operating normally. Safe travels!',
        updatedAt: alertConfig.value.updatedAt || alertConfig.updatedAt || new Date().toISOString()
      });
    }
  } catch (err) {
    console.error('Error fetching dynamic emergency alert config:', err);
  }

  // Fallback to Env Variables
  res.json({
    success: true,
    active: process.env.EMERGENCY_ALERT_ACTIVE === 'true',
    message: process.env.EMERGENCY_ALERT_MESSAGE || 'All routes operating normally. Safe travels!',
    updatedAt: process.env.EMERGENCY_ALERT_TIME || new Date().toISOString()
  });
});

module.exports = router;