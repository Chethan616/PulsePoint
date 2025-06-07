import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/screens/home_screen.dart';
import 'package:pulsepoint_v2/screens/login_screen.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';
import 'auth_service.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            // User is authenticated, update their location silently
            _updateUserLocation();
            return HomeScreen();
          } else {
            return LoginPage();
          }
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  // Update user location when app starts
  Future<void> _updateUserLocation() async {
    // This doesn't need to be awaited since we don't want to block the UI
    LocationUtils.updateUserLocationSilently().then((success) {
      if (success) {
        print('User location updated on app launch');
      } else {
        print('Could not update user location on app launch');
      }
    });
  }
}
