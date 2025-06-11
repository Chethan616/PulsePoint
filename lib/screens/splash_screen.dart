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

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pulsepoint/providers/auth_wrapper.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _hasCompletedAnimation = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _hasCompletedAnimation = true;
        });

        // Navigate to AuthWrapper after the animation completes
        Timer(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AuthWrapper()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF0A0A0A)]
                : [Color(0xFFFF5F6D), Color(0xFFFFC371)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation
            Expanded(
              flex: 3,
              child: Center(
                child: Hero(
                  tag: 'logo',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenSize.width * 0.7,
                      maxHeight: screenSize.height * 0.4,
                    ),
                    child: Lottie.network(
                      // Blood donation animation
                      isDark
                          ? 'https://assets10.lottiefiles.com/packages/lf20_ot5gufvd.json' // Blood cell animation
                          : 'https://assets2.lottiefiles.com/packages/lf20_sdiODl.json', // Blood donation animation
                      controller: _animationController,
                      animate: true,
                      repeat: false,
                      onLoaded: (composition) {
                        _animationController.duration = composition.duration;
                        _animationController.forward();
                      },
                      frameRate: FrameRate.max,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to static icon if Lottie fails
                        _animationController.forward();
                        return Icon(
                          Icons.volunteer_activism,
                          size: 120,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // App name with fade in animation
            Expanded(
              flex: 1,
              child: AnimatedOpacity(
                opacity: _hasCompletedAnimation ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PulsePoint',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connecting Life Savers',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

