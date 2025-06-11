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

// Copyright (C) 2025 <name of author>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulsepoint/providers/auth_service.dart';
import 'package:pulsepoint/providers/auth_wrapper.dart';
import 'package:pulsepoint/providers/theme_provider.dart';
import 'package:pulsepoint/providers/activity_service.dart';
import 'package:pulsepoint/providers/donation_service.dart';
import 'package:pulsepoint/services/notification_service.dart';
import 'package:pulsepoint/user_screens/chat_screen.dart';
import 'package:pulsepoint/user_screens/profile_screen.dart';
import 'package:pulsepoint/screens/splash_screen.dart';
import 'package:pulsepoint/widgets/request_blood.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service
    print('Initializing notification service...');
    await NotificationService().initialize();
    print('Notification service initialized');

    // Initialize home screen widgets
    print('Initializing home screen widgets...');
    try {
      // Initialize HomeWidget package
      // await HomeWidget.setAppGroupId('group.com.example.pulsepoint_v2');
      // await HomeWidget.registerBackgroundCallback(
      //     HomeScreenWidgetManager.backgroundCallback);

      // Initialize widget data
      // await HomeScreenWidgetManager.initialize();

      // Additional initialization for redundancy
      // await Future.delayed(Duration(milliseconds: 500));
      // await HomeScreenWidgetManager.forceRefreshAllWidgets();

      print('Home screen widgets initialized successfully');
    } catch (e) {
      print('Error initializing home screen widgets: $e');
      // Try again with a more direct approach
      try {
        // Manually save widget data directly
        final prefs = await SharedPreferences.getInstance();
        final random = math.Random();
        final healthTips = [
          "Stay hydrated! Drink at least 8 glasses of water daily for better blood flow.",
          "Regular blood donation can reduce the risk of heart disease and lower iron stores.",
          "A single blood donation can save up to three lives - be a hero today!",
          "Males can donate blood every 3 months and females every 4 months safely.",
          "After donating blood, your body replaces the lost red blood cells within 4-8 weeks.",
        ];
        final healthTip = healthTips[random.nextInt(healthTips.length)];

        // Save using all methods
        await prefs.setString('tip', healthTip);
        await prefs.setString('flutter.tip', healthTip);
        await prefs.setString('current_health_tip', healthTip);
        await prefs.setString('flutter.current_health_tip', healthTip);

        // Save with home_widget package
        // await HomeWidget.saveWidgetData<String>('tip', healthTip);

        // Save emergency number
        await prefs.setString('emergency_number', '108');
        await prefs.setString('flutter.emergency_number', '108');
        // await HomeWidget.saveWidgetData<String>('emergency_number', '108');

        // Try to update the widgets
        // await HomeWidget.updateWidget(
        //   name: 'HealthTipWidgetProvider',
        //   androidName: 'HealthTipWidgetProvider',
        //   iOSName: 'HealthTipWidget',
        // );

        // await HomeWidget.updateWidget(
        //   name: 'EmergencyOptionsWidgetProvider',
        //   androidName: 'EmergencyOptionsWidgetProvider',
        //   iOSName: 'EmergencyOptionsWidget',
        // );

        print('Fallback widget initialization completed');
      } catch (fallbackError) {
        print('Even fallback widget initialization failed: $fallbackError');
      }
    }
  } catch (e, stackTrace) {
    print("Error during initialization: $e");
    print("Stack trace: $stackTrace");
  }

  // Initialize widget callback listener
  // HomeWidget.widgetClicked.listen((uri) {
  //   print('Widget clicked: $uri');
  //   // Handle widget click events if needed
  // });

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ActivityService>(create: (_) => ActivityService()),
        Provider<DonationService>(create: (_) => DonationService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PulsePoint',
      theme: themeProvider.themeData,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      routes: {
        '/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return args != null ? _buildChatScreen(args) : AuthWrapper();
        },
        '/blood_request_details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return args != null
              ? _buildBloodRequestDetailsScreen(args)
              : AuthWrapper();
        },
        '/profile': (context) {
          return ProfileScreen();
        },
      },
    );
  }

  Widget _buildChatScreen(Map<String, dynamic> args) {
    final conversationId = args['conversationId'] as String;
    final recipientUserId = args['recipientUserId'] as String;

    // Import the ChatScreen and return it with the parameters
    return ChatScreen(
      conversationId: conversationId,
      recipientUserId: recipientUserId,
    );
  }

  Widget _buildBloodRequestDetailsScreen(Map<String, dynamic> args) {
    final requestId = args['requestId'] as String;

    // Return the ThreadDetailPage with the request ID
    return ThreadDetailPage(threadId: requestId);
  }
}
