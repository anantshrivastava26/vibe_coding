# Building LifeLoop for Release

How to produce an installable build of the Flutter app, and why the release build is
~12x smaller than the debug one.

## TL;DR

```bash
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://vibecoding-production-7d17.up.railway.app
```

Install `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` on the phone.

## Why not the debug APK

`flutter run` and `flutter build apk --debug` produce `app-debug.apk`, which came out at
**220 MB**. That is expected, not a bug. A debug APK contains:

- all four CPU architectures (armeabi-v7a, arm64-v8a, x86, x86_64) in one file
- the JIT Dart engine plus the full Dart VM service / observatory
- unstripped native debug symbols
- no tree-shaking of icon fonts or unused code

A release build strips all of that. Current sizes:

| Artifact | Size | Use |
|---|---|---|
| `app-debug.apk` | 220 MB | local dev only, never ship |
| `app-armeabi-v7a-release.apk` | 16.0 MB | older 32-bit phones |
| `app-arm64-v8a-release.apk` | 18.3 MB | **every phone since ~2017** |
| `app-x86_64-release.apk` | 19.7 MB | emulators only |

`--split-per-abi` is what produces one APK per architecture instead of a single fat one.
Without it a release APK is roughly the sum of the three, around 50 MB. For sideloading,
`arm64-v8a` is essentially always the right file.

## Configuring the backend URL

`lib/config.dart` reads `API_BASE_URL` from the build environment and falls back to a
default. Pass `--dart-define` to point a build at a different backend; nothing in the
source needs editing:

```bash
# Hosted backend (what shipped builds should use)
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://vibecoding-production-7d17.up.railway.app

# Local backend, physical phone on the same Wi-Fi as the dev machine
flutter run --dart-define=API_BASE_URL=http://192.168.1.9:3000

# Local backend, Android emulator (10.0.2.2 is the emulator's alias for host localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` **only** resolves inside the Android emulator. A physical device that tries it
gets `SocketException: Connection timed out` — that address is not routable from a real
phone. Find the dev machine's LAN IP with `ipconfig` (Windows) or `ifconfig` (macOS/Linux).

### Plaintext HTTP is debug-only

Release builds do not permit cleartext traffic. `android:usesCleartextTraffic="true"` lives
in `android/app/src/debug/AndroidManifest.xml`, so it is merged into debug builds only.

This means a **release** build can only talk to an `https://` backend. Pointing one at
`http://192.168.1.9:3000` will fail with a cleartext-not-permitted error. Use a debug or
profile build when developing against a local backend, which is the normal workflow anyway.

## Play Store builds

The Play Store takes an App Bundle, not APKs. Google splits it per-device on their side,
so `--split-per-abi` is neither needed nor allowed:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://vibecoding-production-7d17.up.railway.app
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

## Signing

`android/app/build.gradle.kts` currently signs release builds with the **debug keystore**:

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

That is fine for sideloading onto your own phone and for sharing an APK directly. It is
not acceptable for the Play Store, and builds signed with a debug key cannot later be
replaced by properly-signed ones without uninstalling. Before publishing, generate an
upload keystore and replace that line:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then follow https://docs.flutter.dev/deployment/android#signing-the-app. Keep the keystore
and its passwords out of git.

## Size optimisations already enabled

In `android/app/build.gradle.kts`, the release build type sets:

- `isMinifyEnabled = true` — R8 strips unused Java/Kotlin classes and obfuscates
- `isShrinkResources = true` — drops unreferenced Android resources

`android/app/proguard-rules.pro` holds the keep-rules these need. `flutter_local_notifications`
serialises scheduled notifications reflectively via Gson, so its classes are kept explicitly;
without that rule, scheduled notifications break only in release builds.

Icon-font tree-shaking is automatic and reports itself during the build (MaterialIcons drops
from 1.6 MB to ~6 KB).

## Verifying a release build

Release builds have no hot reload and no debug console, so check them explicitly:

```bash
# Install straight to a connected phone
flutter install --release

# Or run with logs attached
flutter run --release --dart-define=API_BASE_URL=https://vibecoding-production-7d17.up.railway.app
```

Worth exercising after any change to minification rules, since R8 problems appear only in
release: login, notifications (foreground and with the app closed), the map screen, and
location permission prompts.
