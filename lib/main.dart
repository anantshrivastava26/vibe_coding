import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/location_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const LifeLoopApp());
}

class LifeLoopApp extends StatelessWidget {
  const LifeLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'LifeLoop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

// Routes between sign-in, location onboarding, and the main app based on
// auth + profile state, with a cross-fade so the switch isn't jarring.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    final Widget screen;
    if (!auth.isLoggedIn) {
      screen = const LoginScreen();
    } else if (auth.loading) {
      screen = const _SplashScreen();
    } else if (auth.profile == null) {
      screen = _ErrorScreen(message: auth.lastError ?? 'Could not reach the server.');
    } else if (!auth.profile!.hasLocation) {
      screen = const LocationSetupScreen();
    } else {
      screen = const HomeShell();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(key: ValueKey(screen.runtimeType), child: screen),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.crisis_alert, size: 64, color: Colors.white),
              SizedBox(height: 20),
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: AppColors.coral500),
              const SizedBox(height: 16),
              Text('Connection problem', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuthService>().syncProfile(),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => context.read<AuthService>().logout(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
