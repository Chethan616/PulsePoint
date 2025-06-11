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
// import 'package:home_widget/home_widget.dart';
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
      // Configure for both platforms
      // await HomeWidget.setAppGroupId('group.com.example.pulsepoint_v2');

      // Set up background handlers
      // await HomeWidget.registerBackgroundCallback(backgroundCallback);

      // Initialize widget data
      await refreshHealthTipWidget();
      await updateEmergencyNumber('108'); // Default number

      // Update the widgets
      /* 
      await HomeWidget.updateWidget(
        name: 'HealthTipWidgetProvider',
        androidName: 'HealthTipWidgetProvider',
        iOSName: 'HealthTipWidget',
      );

      await HomeWidget.updateWidget(
        name: 'EmergencyOptionsWidgetProvider',
        androidName: 'EmergencyOptionsWidgetProvider',
        iOSName: 'EmergencyOptionsWidget',
      );
      */

      print('Home screen widgets initialized successfully');
    } catch (e) {
      print('Error initializing home screen widgets: $e');
    }
  }

  // Background callback for widget actions
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    print('Background callback triggered with URI: $uri');

    if (uri.host == 'refreshtip') {
      await refreshHealthTipWidget();
    } else if (uri.host == 'emergency') {
      if (uri.path == '/call') {
        final prefs = await SharedPreferences.getInstance();
        final emergencyNumber = prefs.getString(_emergencyNumberKey) ?? '108';

        final call = Uri.parse('tel:$emergencyNumber');
        if (await canLaunchUrl(call)) {
          await launchUrl(call);
        }
      }
    }
  }

  // Refresh the health tip widget
  static Future<void> refreshHealthTipWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final random = Random();
      final newTip = _healthTips[random.nextInt(_healthTips.length)];

      // Save to shared preferences (for Flutter access)
      await prefs.setString(_healthTipKey, newTip);

      // Save for widget access
      // await HomeWidget.saveWidgetData<String>('tip', newTip);

      // For backward compatibility, save with other keys too
      await prefs.setString('flutter.current_health_tip', newTip);
      await prefs.setString('tip', newTip);
      await prefs.setString('flutter.tip', newTip);

      // Update the widget
      /*
      await HomeWidget.updateWidget(
        name: 'HealthTipWidgetProvider',
        androidName: 'HealthTipWidgetProvider',
        iOSName: 'HealthTipWidget',
      );
      */

      print('Health tip widget refreshed with: $newTip');
    } catch (e) {
      print('Error refreshing health tip widget: $e');
    }
  }

  // Force refresh all widgets
  static Future<void> forceRefreshAllWidgets() async {
    try {
      print('Force refreshing all widgets...');

      // Refresh health tip widget
      await refreshHealthTipWidget();

      // Refresh emergency widget (if needed)
      final prefs = await SharedPreferences.getInstance();
      final emergencyNumber = prefs.getString(_emergencyNumberKey) ?? '108';
      await updateEmergencyNumber(emergencyNumber);

      print('All widgets refreshed successfully');
    } catch (e) {
      print('Error force refreshing widgets: $e');
    }
  }

  // Update emergency contact number
  static Future<void> updateEmergencyNumber(String number) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emergencyNumberKey, number);

      // Save for widget access
      // await HomeWidget.saveWidgetData<String>('emergency_number', number);

      // For backward compatibility
      await prefs.setString('flutter.emergency_number', number);

      // Update widget
      /*
      await HomeWidget.updateWidget(
        name: 'EmergencyOptionsWidgetProvider',
        androidName: 'EmergencyOptionsWidgetProvider',
        iOSName: 'EmergencyOptionsWidget',
      );
      */

      print('Emergency number updated to: $number');
    } catch (e) {
      print('Error updating emergency number: $e');
    }
  }
}

