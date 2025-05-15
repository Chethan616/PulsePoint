import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulsepoint_v2/providers/auth_service.dart';
import 'package:pulsepoint_v2/providers/auth_wrapper.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:pulsepoint_v2/providers/activity_service.dart';
import 'package:pulsepoint_v2/providers/donation_service.dart';
import 'package:pulsepoint_v2/services/notification_service.dart';
import 'package:pulsepoint_v2/user_screens/chat_screen.dart';
import 'package:pulsepoint_v2/user_screens/profile_screen.dart';
import 'package:pulsepoint_v2/screens/splash_screen.dart';
import 'package:pulsepoint_v2/widgets/request_blood.dart';
import 'package:pulsepoint_v2/widgets/home_screen_widgets/home_screen_widget_manager.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:pulsepoint_v2/widgets/home_widget_custom/home_widget.dart';
// import 'package:home_widget/home_widget.dart';
import 'package:pulsepoint_v2/screens/widget_debug_screen.dart';

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
