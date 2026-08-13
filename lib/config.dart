// Backend base URL.
//
// Override without editing this file:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.9:3000
//
// - Physical device: your machine's LAN IP (both must be on the same Wi-Fi).
// - Android emulator: http://10.0.2.2:3000
// - Once deployed, the Railway URL (e.g. https://your-app.up.railway.app).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.9:3000',
);
