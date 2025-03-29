import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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
    // Check for Google Maps API key (optional, since flutter_map uses OSM)
    final googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (googleMapsApiKey.isEmpty) {
      print('Warning: GOOGLE_MAPS_API_KEY not found in .env. This app uses OpenStreetMap, so it may not be required.');
    }

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
            return const Scaffold(
              body: Center(child: Text('Error loading app')),
            );
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
                return const Scaffold(
                  body: Center(child: Text('Error checking auth state')),
                );
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