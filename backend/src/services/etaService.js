const axios = require('axios');
const { haversineKm, estimateEtaMinutes } = require('../utils/distance');

const ETA_SERVICE_URL = process.env.ETA_SERVICE_URL || 'http://localhost:8000';

/**
 * Predicts ETA using AI microservice, with fallback to simple math.
 */
async function predictEta({ busLat, busLng, stopLat, stopLng, speed, hour }) {
  const dist = haversineKm(busLat, busLng, stopLat, stopLng);
  
  if (process.env.ETA_SERVICE_URL) {
    try {
      const response = await axios.post(`${ETA_SERVICE_URL}/predict-eta`, {
        distance_km: dist,
        speed_kmh: speed,
        hour: hour,
        weather: 'clear', // Default weather
      });
      if (response.data && response.data.eta_minutes !== undefined) {
        return {
          distanceKm: Math.round(dist * 100) / 100,
          etaMinutes: Math.round(response.data.eta_minutes),
          source: 'ai'
        };
      }
    } catch (error) {
      console.warn(`[ETA Service] AI ETA failed, falling back to math: ${error.message}`);
    }
  }

  // Fallback
  return {
    distanceKm: Math.round(dist * 100) / 100,
    etaMinutes: estimateEtaMinutes(dist, speed, hour),
    source: 'math'
  };
}

module.exports = { predictEta };
