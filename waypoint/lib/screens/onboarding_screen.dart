import 'package:flutter/material.dart';
import 'map_screen.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Waypoint!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('Discover and create events on campus.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapScreen())),
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}