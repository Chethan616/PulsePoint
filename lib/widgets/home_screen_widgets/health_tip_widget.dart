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
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulsepoint/widgets/home_widget_custom/home_widget.dart'; // Your custom implementation

class HealthTipWidget extends StatefulWidget {
  const HealthTipWidget({Key? key}) : super(key: key);

  @override
  _HealthTipWidgetState createState() => _HealthTipWidgetState();
}

class _HealthTipWidgetState extends State<HealthTipWidget> {
  String _currentTip = 'Loading health tip...';
  static const String _tipKey = 'current_health_tip';

  static const List<String> _healthTips = [
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

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  Future<void> _initializeWidget() async {
    await _loadTip();
    await _setupHomeWidget();
  }

  Future<void> _loadTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentTip = prefs.getString(_tipKey) ?? _getRandomTip();
      });
    } catch (e) {
      print('Error loading tip: $e');
      setState(() {
        _currentTip = _getRandomTip();
      });
    }
  }

  String _getRandomTip() {
    final random = Random();
    return _healthTips[random.nextInt(_healthTips.length)];
  }

  Future<void> _refreshTip() async {
    final newTip = _getRandomTip();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tipKey, newTip);

      setState(() {
        _currentTip = newTip;
      });

      await _updateWidget(newTip);
    } catch (e) {
      print('Error refreshing tip: $e');
    }
  }

  Future<void> _setupHomeWidget() async {
    try {
      // Set app group ID (iOS only)
      await HomeWidgetCustom.setAppGroupId('group.com.example.pulsepoint_v2');

      // Register callback
      await HomeWidgetCustom.registerBackgroundCallback(_backgroundCallback);

      // Update widget with current tip
      await _updateWidget(_currentTip);

      // Listen for widget clicks
      HomeWidgetCustom.widgetClicked.listen(_handleWidgetClick);
    } catch (e) {
      print('Error setting up home widget: $e');
    }
  }

  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri?.host == 'refreshtip') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final newTip = _healthTips[Random().nextInt(_healthTips.length)];

        await prefs.setString(_tipKey, newTip);
        await HomeWidgetCustom.saveWidgetData('tip', newTip);
        await HomeWidgetCustom.updateWidget(
          name: 'HealthTipWidgetProvider',
          androidName: 'HealthTipWidgetProvider',
          iOSName: 'HealthTipWidget',
        );
      } catch (e) {
        print('Background callback error: $e');
      }
    }
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri?.host == 'refreshtip') {
      _refreshTip();
    }
  }

  Future<void> _updateWidget(String tip) async {
    try {
      await HomeWidgetCustom.saveWidgetData('tip', tip);
      await HomeWidgetCustom.updateWidget(
        name: 'HealthTipWidgetProvider',
        androidName: 'HealthTipWidgetProvider',
        iOSName: 'HealthTipWidget',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _refreshTip,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Color(0xFF1E1E1E), Color(0xFF2A2A2A)]
                  : [Color(0xFF6200EE), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Health Tip",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refreshTip,
                    tooltip: 'Refresh tip',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currentTip,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap to refresh",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
