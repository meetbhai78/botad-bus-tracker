// Use --dart-define=API_BASE_URL=... to override. 
// Default is 10.0.2.2 for Android emulator. Use physical IP for real devices.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
const String socketUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');

// Use --dart-define=MAPTILER_KEY=...
const String maptilerKey = String.fromEnvironment('MAPTILER_KEY', defaultValue: 'YOUR_MAPTILER_KEY');
