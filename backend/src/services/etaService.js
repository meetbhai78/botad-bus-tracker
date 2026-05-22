const { haversineKm, estimateEtaMinutes } = require('../utils/distance');

/**
 * Predicts ETA using FastAPI `ai-eta` service (`POST /predict-eta`), with fallback to simple math.
 * Contract must match `ai-eta/main.py` ETARequest.
 */
async function predictEta({ busLat, busLng, stopLat, stopLng, speed, hour }) {
  const dist = haversineKm(busLat, busLng, stopLat, stopLng);
  const baseUrl = (process.env.ETA_SERVICE_URL || '').replace(/\/$/, '');

  if (baseUrl) {
    try {
      const res = await fetch(`${baseUrl}/predict-eta`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          bus_lat: busLat,
          bus_lng: busLng,
          stop_lat: stopLat,
          stop_lng: stopLng,
          current_speed: Math.max(Number(speed) || 0, 15),
          hour_of_day: hour,
          day_of_week: new Date().getDay(),
        }),
      });
      if (res.ok) {
        const data = await res.json();
        if (data && data.eta_minutes !== undefined) {
          return {
            distanceKm: typeof data.distance_km === 'number' ? data.distance_km : Math.round(dist * 100) / 100,
            etaMinutes: Math.round(Number(data.eta_minutes)),
            source: 'ai',
          };
        }
      }
    } catch (err) {
      console.warn(`[ETA Service] AI ETA failed, falling back to math: ${err.message}`);
    }
  }

  return {
    distanceKm: Math.round(dist * 100) / 100,
    etaMinutes: estimateEtaMinutes(dist, speed, hour),
    source: 'math',
  };
}

module.exports = { predictEta };
