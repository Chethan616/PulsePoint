import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulsepoint_v2/providers/auth_service.dart';
import 'package:pulsepoint_v2/providers/auth_wrapper.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:pulsepoint_v2/providers/activity_service.dart';
import 'package:pulsepoint_v2/providers/donation_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
    );
  }
}
