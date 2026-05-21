// Use --dart-define=API_BASE_URL=... to override. 
// Default is live server for production. Use physical IP/localhost for testing.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://botad-bus-tracker.onrender.com');
const String socketUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://botad-bus-tracker.onrender.com');

// Use --dart-define=MAPTILER_KEY=...
const String maptilerKey = String.fromEnvironment('MAPTILER_KEY', defaultValue: 'YOUR_MAPTILER_KEY');
