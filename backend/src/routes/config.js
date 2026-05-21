const express = require('express');
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

module.exports = router;