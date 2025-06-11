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
import 'package:pulsepoint/widgets/home_screen_widgets/home_screen_widget_manager.dart';
// import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetDebugScreen extends StatefulWidget {
  const WidgetDebugScreen({Key? key}) : super(key: key);

  @override
  _WidgetDebugScreenState createState() => _WidgetDebugScreenState();
}

class _WidgetDebugScreenState extends State<WidgetDebugScreen> {
  String _statusMessage = '';
  bool _isLoading = false;
  Map<String, String> _prefsData = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading preferences...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      Map<String, String> data = {};
      for (var key in keys) {
        data[key] = prefs.getString(key) ?? 'null';
      }

      setState(() {
        _prefsData = data;
        _statusMessage = 'Preferences loaded successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading preferences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _manualInitializeWidgets() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing widgets...';
    });

    try {
      // Initialize app group ID
      // await HomeWidget.setAppGroupId('group.com.example.pulsepoint_v2');

      // Manual save of widget data
      // await HomeWidget.saveWidgetData<String>('tip',
      //    'Manually set health tip: Stay hydrated and exercise regularly!');
      // await HomeWidget.saveWidgetData<String>('emergency_number', '108');

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tip',
          'Manually set health tip: Stay hydrated and exercise regularly!');
      await prefs.setString('emergency_number', '108');

      setState(() {
        _statusMessage =
            'Data saved to SharedPreferences (widget functionality disabled)';
      });

      await _loadPreferences();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing widgets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshHealthTip() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Refreshing health tip...';
    });

    try {
      await HomeScreenWidgetManager.refreshHealthTipWidget();
      setState(() {
        _statusMessage = 'Health tip refreshed successfully';
      });
      await _loadPreferences();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error refreshing health tip: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceUpdateWidgets() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Force updating widgets...';
    });

    try {
      await HomeScreenWidgetManager.forceRefreshAllWidgets();
      setState(() {
        _statusMessage = 'Widgets updated successfully';
      });
      await _loadPreferences();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating widgets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget Debug'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(_statusMessage),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Action buttons
                  Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _manualInitializeWidgets,
                    icon: Icon(Icons.developer_mode),
                    label: Text('Manual Widget Init'),
                  ),

                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _refreshHealthTip,
                    icon: Icon(Icons.lightbulb),
                    label: Text('Refresh Health Tip'),
                  ),

                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _forceUpdateWidgets,
                    icon: Icon(Icons.refresh),
                    label: Text('Force Update All Widgets'),
                  ),

                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _loadPreferences,
                    icon: Icon(Icons.storage),
                    label: Text('Reload Preferences'),
                  ),

                  SizedBox(height: 24),

                  // Shared Preferences Data
                  Text(
                    'Shared Preferences Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  if (_prefsData.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No data found in SharedPreferences'),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _prefsData.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          String key = _prefsData.keys.elementAt(index);
                          String value = _prefsData[key] ?? 'null';

                          return ListTile(
                            title: Text(key),
                            subtitle: Text(value),
                            dense: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
