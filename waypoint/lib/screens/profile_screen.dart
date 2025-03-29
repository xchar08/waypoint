import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _authService.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
          },
          child: Text('Sign Out'),
        ),
      ),
    );
  }
}