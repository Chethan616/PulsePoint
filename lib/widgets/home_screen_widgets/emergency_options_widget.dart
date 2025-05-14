import 'package:flutter/material.dart';
import 'package:pulsepoint_v2/widgets/home_widget_custom/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyOptionsWidget extends StatefulWidget {
  const EmergencyOptionsWidget({Key? key}) : super(key: key);

  @override
  _EmergencyOptionsWidgetState createState() => _EmergencyOptionsWidgetState();
}

class _EmergencyOptionsWidgetState extends State<EmergencyOptionsWidget> {
  static const String _emergencyNumberKey = 'emergency_number';
  String _emergencyNumber = '108'; // Default emergency number in India

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupHomeWidget();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyNumber = prefs.getString(_emergencyNumberKey) ?? '108';
    });
  }

  void _setupHomeWidget() async {
    // Initialize home widget with app group ID (for iOS)
    await HomeWidgetCustom.setAppGroupId('group.com.example.pulsepoint_v2');

    // Register for widget updates
    HomeWidgetCustom.registerBackgroundCallback(_backgroundCallback);

    // Save emergency number to widget data
    await HomeWidgetCustom.saveWidgetData('emergency_number', _emergencyNumber);

    // Listen for widget clicks
    HomeWidgetCustom.widgetClicked.listen(_widgetClicked);

    // Update widget
    _updateWidget();
  }

  // Background callback for widget clicks
  static void _backgroundCallback(Uri? uri) async {
    if (uri?.host == 'emergency') {
      final prefs = await SharedPreferences.getInstance();
      final emergencyNumber = prefs.getString(_emergencyNumberKey) ?? '108';

      // Handle different actions based on the path
      if (uri?.path == '/call') {
        final call = Uri.parse('tel:$emergencyNumber');
        if (await canLaunchUrl(call)) {
          await launchUrl(call);
        }
      } else if (uri?.path == '/hospitals') {
        _findNearbyHospitals();
      }
    }
  }

  void _widgetClicked(Uri? uri) {
    if (uri?.host == 'emergency') {
      // Handle widget clicks based on path
      if (uri?.path == '/call') {
        _callEmergency();
      } else if (uri?.path == '/hospitals') {
        _findNearbyHospitals();
      }
    }
  }

  Future<void> _updateWidget() async {
    try {
      await HomeWidgetCustom.updateWidget(
        name: 'EmergencyOptionsWidgetProvider',
        androidName: 'EmergencyOptionsWidgetProvider',
        iOSName: 'EmergencyOptionsWidget',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  void _callEmergency() async {
    final call = Uri.parse('tel:$_emergencyNumber');
    if (await canLaunchUrl(call)) {
      await launchUrl(call);
    }
  }

  static Future<void> _findNearbyHospitals() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Open Google Maps with nearby hospitals query
      final url =
          'https://www.google.com/maps/search/?api=1&query=hospitals+near+me&query_place_id=${position.latitude},${position.longitude}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error finding nearby hospitals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.red[900] : Colors.red[800],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  "Emergency Options",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildEmergencyOption(
              icon: Icons.phone,
              title: "Call Emergency ($_emergencyNumber)",
              onTap: _callEmergency,
            ),
            SizedBox(height: 12),
            _buildEmergencyOption(
              icon: Icons.local_hospital,
              title: "Find Nearby Hospitals",
              onTap: () => _findNearbyHospitals(),
            ),
            SizedBox(height: 12),
            _buildEmergencyOption(
              icon: Icons.bloodtype,
              title: "Blood Request",
              onTap: () {
                Navigator.pushNamed(context, '/blood_request');
              },
            ),
            SizedBox(height: 8),
            Text(
              "Quick access to emergency services",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}
