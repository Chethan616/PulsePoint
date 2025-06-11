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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulsepoint/providers/theme_provider.dart';
import 'package:pulsepoint/widgets/home_screen_widgets/home_screen_widget_manager.dart';
import 'package:pulsepoint/widgets/home_screen_widgets/health_tip_widget.dart';
import 'package:pulsepoint/widgets/home_screen_widgets/emergency_options_widget.dart';

class WidgetsSettingsScreen extends StatefulWidget {
  const WidgetsSettingsScreen({Key? key}) : super(key: key);

  @override
  _WidgetsSettingsScreenState createState() => _WidgetsSettingsScreenState();
}

class _WidgetsSettingsScreenState extends State<WidgetsSettingsScreen> {
  late TextEditingController _emergencyNumberController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _emergencyNumberController = TextEditingController();
    _loadEmergencyNumber();
  }

  @override
  void dispose() {
    _emergencyNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyNumber() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String emergencyNumber = prefs.getString('emergency_number') ?? '108';

    setState(() {
      _emergencyNumberController.text = emergencyNumber;
      _isLoading = false;
    });
  }

  Future<void> _updateEmergencyNumber() async {
    String number = _emergencyNumberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency number cannot be empty')),
      );
      return;
    }

    await HomeScreenWidgetManager.updateEmergencyNumber(number);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emergency number updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Screen Widgets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  SizedBox(height: 20),

                  // Emergency Number Section
                  _buildSectionHeader('Emergency Number'),
                  SizedBox(height: 12),
                  _buildInputField(
                    title: 'Emergency Contact Number',
                    hint: 'Enter emergency number',
                    controller: _emergencyNumberController,
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _updateEmergencyNumber(),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _updateEmergencyNumber,
                    child: Text('Update Emergency Number'),
                  ),
                  SizedBox(height: 32),

                  // Preview Section
                  _buildSectionHeader('Widget Previews'),
                  SizedBox(height: 16),
                  Text(
                    'These widgets can be added to your home screen for quick access:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),

                  // Health Tip Widget Preview
                  Container(
                    width: double.infinity,
                    child: HealthTipWidget(),
                  ),
                  SizedBox(height: 20),

                  // Emergency Options Widget Preview
                  Container(
                    width: double.infinity,
                    child: EmergencyOptionsWidget(),
                  ),
                  SizedBox(height: 32),

                  // Fix Widgets Section
                  _buildSectionHeader('Troubleshoot Widgets'),
                  SizedBox(height: 12),
                  Text(
                    'If your widgets are not displaying correctly, try refreshing them:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),

                  // Widget Refresh Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Refreshing widgets...')),
                      );

                      await HomeScreenWidgetManager.forceRefreshAllWidgets();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Widgets refreshed successfully')),
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh All Widgets'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      textStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Health Tip Refresh Button
                  ElevatedButton(
                    onPressed: () async {
                      await HomeScreenWidgetManager.refreshHealthTipWidget();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Health tip refreshed')),
                      );
                    },
                    child: Text('Refresh Health Tip'),
                  ),
                  SizedBox(height: 32),

                  // Instructions Section
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.widgets, color: Theme.of(context).primaryColor),
                SizedBox(width: 12),
                Text(
                  'Home Screen Widgets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'PulsePoint provides home screen widgets for quick access to important features. '
              'Customize them below.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.settings, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String title,
    required String hint,
    required TextEditingController controller,
    required TextInputType keyboardType,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Add Widgets to Home Screen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildInstructionStep(
              number: '1',
              text: 'Long press on an empty area of your home screen.',
            ),
            _buildInstructionStep(
              number: '2',
              text: 'Tap "Widgets" in the menu that appears.',
            ),
            _buildInstructionStep(
              number: '3',
              text: 'Scroll to find "PulsePoint" widgets or search for them.',
            ),
            _buildInstructionStep(
              number: '4',
              text:
                  'Press and hold the widget, then drag to place it on your home screen.',
            ),
            _buildInstructionStep(
              number: '5',
              text: 'Adjust the widget size if needed.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
