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
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service
    await NotificationService().init();
  } catch (e) {
    print("Firebase initialization error: $e");
  }
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
      home: AuthWrapper(),
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

    // For now, handle a missing screen by returning to the auth wrapper
    // Later this should be replaced with the actual blood request details screen
    return AuthWrapper();
  }
}
