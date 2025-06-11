// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Copyright (C) 2025  Author Name

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint/screens/home_screen.dart';
import 'package:pulsepoint/screens/login_screen.dart';
import 'package:pulsepoint/utilities/location_utils.dart';
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

