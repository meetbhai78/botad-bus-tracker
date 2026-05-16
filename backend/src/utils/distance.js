/** Haversine distance in km — ETA ke liye */
function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function estimateEtaMinutes(distanceKm, speedKmh, hourOfDay) {
  let multiplier = 1;
  if ([8, 9, 17, 18].includes(hourOfDay)) multiplier = 1.4;
  else if (hourOfDay < 6 || hourOfDay > 22) multiplier = 0.8;
  const avgSpeed = Math.max(speedKmh || 0, 15);
  return Math.round(((distanceKm / avgSpeed) * 60 * multiplier) * 10) / 10;
}

module.exports = { haversineKm, estimateEtaMinutes };
