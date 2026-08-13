// Backend base URL.
//
// Override without editing this file:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.9:3000
//
// Defaults to the hosted Railway backend, which every install can reach.
// Point at a local backend only for development:
// - Physical device: your machine's LAN IP (both must be on the same Wi-Fi).
// - Android emulator: http://10.0.2.2:3000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://vibecoding-production-7d17.up.railway.app',
);
