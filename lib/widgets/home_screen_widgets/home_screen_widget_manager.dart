import 'package:flutter/material.dart';
import 'package:pulsepoint_v2/widgets/home_widget_custom/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class HomeScreenWidgetManager {
  static const String _healthTipKey = 'current_health_tip';
  static const String _emergencyNumberKey = 'emergency_number';

  static final List<String> _healthTips = [
    "Stay hydrated! Drink at least 8 glasses of water daily for better blood flow.",
    "Regular blood donation can reduce the risk of heart disease and lower iron stores.",
    "A single blood donation can save up to three lives - be a hero today!",
    "Males can donate blood every 3 months and females every 4 months safely.",
    "After donating blood, your body replaces the lost red blood cells within 4-8 weeks.",
    "Eat iron-rich foods like spinach and meat before donating blood to boost hemoglobin.",
    "Blood donation helps in reducing the risk of cancer by eliminating excess iron.",
    "Walking 30 minutes daily improves cardiovascular health and blood circulation.",
    "Avoid fatty foods before donating blood as it can affect the quality of donation.",
    "Getting enough sleep (7-8 hours) helps maintain healthy blood pressure levels."
  ];

  // Initialize home screen widgets
  static Future<void> initialize() async {
    try {
      await HomeWidgetCustom.setAppGroupId('group.com.example.pulsepoint_v2');

      // Register background callbacks for widgets
      HomeWidgetCustom.registerBackgroundCallback(backgroundCallback);

      // Initialize widgets with data
      await refreshHealthTipWidget();
      await updateEmergencyNumber('108'); // Default number

      // Listen for widget launches
      HomeWidgetCustom.widgetClicked.listen(_handleWidgetClick);

      print('Home screen widgets initialized successfully');
    } catch (e) {
      print('Error initializing home screen widgets: $e');
    }
  }

  // Background callback for widget actions
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'refreshtip') {
      await refreshHealthTipWidget();
    } else if (uri?.host == 'emergency') {
      if (uri?.path == '/call') {
        final prefs = await SharedPreferences.getInstance();
        final emergencyNumber = prefs.getString(_emergencyNumberKey) ?? '108';

        final call = Uri.parse('tel:$emergencyNumber');
        if (await canLaunchUrl(call)) {
          await launchUrl(call);
        }
      }
    }
  }

  // Handle widget clicks
  static Future<void> _handleWidgetClick(Uri? uri) async {
    print('Widget clicked with URI: $uri');

    if (uri?.host == 'refreshtip') {
      await refreshHealthTipWidget();
    } else if (uri?.host == 'emergency') {
      if (uri?.path == '/hospitals') {
        // Handle finding hospitals
        print('Finding nearby hospitals from widget click');
      } else if (uri?.path == '/blood_request') {
        // Handle blood request
        print('Opening blood request from widget click');
      }
    }
  }

  // Refresh the health tip widget
  static Future<void> refreshHealthTipWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final random = Random();
      final newTip = _healthTips[random.nextInt(_healthTips.length)];

      // Save to shared preferences
      await prefs.setString(_healthTipKey, newTip);

      // Save to widget
      await HomeWidgetCustom.saveWidgetData('tip', newTip);

      // Update widget
      await HomeWidgetCustom.updateWidget(
        name: 'HealthTipWidgetProvider',
        androidName: 'HealthTipWidgetProvider',
        iOSName: 'HealthTipWidget',
      );

      print('Health tip widget refreshed with: $newTip');
    } catch (e) {
      print('Error refreshing health tip widget: $e');
    }
  }

  // Update emergency contact number
  static Future<void> updateEmergencyNumber(String number) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emergencyNumberKey, number);

      // Save to widget
      await HomeWidgetCustom.saveWidgetData('emergency_number', number);

      // Update widget
      await HomeWidgetCustom.updateWidget(
        name: 'EmergencyOptionsWidgetProvider',
        androidName: 'EmergencyOptionsWidgetProvider',
        iOSName: 'EmergencyOptionsWidget',
      );

      print('Emergency number updated to: $number');
    } catch (e) {
      print('Error updating emergency number: $e');
    }
  }
}
