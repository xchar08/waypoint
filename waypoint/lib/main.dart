import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  Future<bool> _checkFirstTime() async {
    return prefs.getBool('isFirstTime') ?? true;
  }

  Future<bool> _checkAuthState() async {
    return AuthService().handleAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waypoint',
      theme: appTheme(),
      home: FutureBuilder<bool>(
        future: _checkFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading app'));
          }
          final isFirstTime = snapshot.data ?? true;
          if (isFirstTime) {
            return OnboardingScreen();
          }
          return FutureBuilder<bool>(
            future: _checkAuthState(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (authSnapshot.hasError) {
                return const Center(child: Text('Error checking auth state'));
              }
              final isAuthenticated = authSnapshot.data ?? false;
              return isAuthenticated ? MapScreen() : LoginScreen();
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Waypoint...'),
          ],
        ),
      ),
    );
  }
}