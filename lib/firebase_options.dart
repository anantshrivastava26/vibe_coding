import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

// Hand-written from android/../google-services.json (project vibe-coding4726)
// so we don't depend on the interactive `flutterfire configure` CLI.
// Android-only: extend with iOS/web options if those platforms are targeted.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have only been configured for Android.',
    );
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAGfbeVVynkVhrOHYyRPLOlovii4WkTpww',
    appId: '1:4696981329:android:2b34382aec277a6c85dd70',
    messagingSenderId: '4696981329',
    projectId: 'vibe-coding4726',
    storageBucket: 'vibe-coding4726.firebasestorage.app',
  );
}
