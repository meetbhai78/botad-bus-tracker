// Use --dart-define=API_BASE_URL=... to override. 
// Default is live server for production. Use physical IP/localhost for testing.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://botad-bus-tracker.onrender.com');
const String socketUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://botad-bus-tracker.onrender.com');

// Use --dart-define=MAPTILER_KEY=...
const String maptilerKey = String.fromEnvironment('MAPTILER_KEY', defaultValue: 'd39cWWFDlw1ibSbMysvD');

String get mapTileUrl {
  if (maptilerKey == 'YOUR_MAPTILER_KEY' || maptilerKey.trim().isEmpty || maptilerKey.contains('YOUR')) {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }
  return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey';
}

