import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:url_launcher/url_launcher.dart';
import 'package:pulsepoint_v2/screens/login_screen.dart';
import 'package:pulsepoint_v2/screens/settings_screen.dart';
import 'package:pulsepoint_v2/screens/history_screen.dart';
import 'package:pulsepoint_v2/user_screens/profile_screen.dart';
import 'package:pulsepoint_v2/providers/auth_service.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:pulsepoint_v2/models/activity_record.dart';
import 'package:pulsepoint_v2/providers/activity_service.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/widgets/donate_blood.dart';
import 'package:pulsepoint_v2/widgets/request_blood.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:map_launcher/map_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _locationMessage = '';
  late ActivityService _activityService;
  late AnimationController _animationController;
  late String _currentTip;
  final List<String> _healthTips = [
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
    _activityService = ActivityService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Select a random tip at initialization
    final random = math.Random();
    _currentTip = _healthTips[random.nextInt(_healthTips.length)];

    // Update user location
    _updateUserLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // If animation is showing the sun but we're in dark mode, or vice versa, fix it
    if ((isDark && _animationController.value == 0) ||
        (!isDark && _animationController.value == 1)) {
      _animationController.value = isDark ? 1 : 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PulsePoint",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, authService, isDark),
      body: _buildBody(context, isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add emergency feature
          _showEmergencyOptions(context);
        },
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(Icons.emergency),
        tooltip: 'Emergency',
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Color(0xFF1E1E1E), Color(0xFF2A2A2A)]
                        : [Color(0xFF6200EE), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF6200EE).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Welcome to PulsePoint",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Connecting lifesavers with those in need",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    // Weather widget or health tip could go here
                    SizedBox(height: 16),
                    _buildHealthTip(isDark),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Main Action Buttons
              Text(
                "What would you like to do?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Find Nearby Hospitals Button
              _buildActionButton(
                title: "Find Nearby Hospitals",
                subtitle: "Locate medical facilities around you",
                icon: Icons.local_hospital_rounded,
                iconColor: Colors.white,
                backgroundColor: isDark ? Color(0xFF03DAC6) : Color(0xFF03DAC5),
                onPressed: () {
                  _findNearbyHospitals();
                  // Record this activity
                  _activityService.recordActivity(
                    type: ActivityType.hospitalVisit,
                    title: "Hospital Search",
                    description: "Searched for nearby hospitals",
                  );
                },
              ),

              SizedBox(height: 16),

              // Donors Near You Button
              _buildActionButton(
                title: "Donors Near You",
                subtitle: "Save a life today",
                icon: Icons.favorite_rounded,
                iconColor: Colors.white,
                backgroundColor: isDark ? Color(0xFFCF6679) : Color(0xFFFF3D71),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DonateBloodScreen()),
                  );
                  // Record this activity
                  _activityService.recordActivity(
                    type: ActivityType.bloodDonation,
                    title: "Blood Donation",
                    description: "Viewed blood donors",
                  );
                },
              ),

              SizedBox(height: 16),

              // Request Blood Button
              _buildActionButton(
                title: "Request Blood",
                subtitle: "Request blood from donors",
                icon: Icons.bloodtype_rounded,
                iconColor: Colors.white,
                backgroundColor: isDark ? Color(0xFFBB86FC) : Color(0xFF9C27B0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BloodPage()),
                  );
                  // Record this activity
                  _activityService.recordActivity(
                    type: ActivityType.bloodRequest,
                    title: "Blood Request",
                    description: "Requested blood from donors",
                  );
                },
              ),

              SizedBox(height: 16),

              // Blood Compatibility Chart
              _buildBloodCompatibilityCard(isDark),

              SizedBox(height: 24),

              // Location Status Message
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),

              if (_locationMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2A2A2A) : Color(0xFFE8DEF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Color(0xFF6200EE).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(_locationMessage),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTip(bool isDark) {
    return GestureDetector(
      onTap: () {
        // Generate a new random tip when tapped
        setState(() {
          final random = math.Random();
          _currentTip = _healthTips[random.nextInt(_healthTips.length)];
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.yellow),
                SizedBox(width: 8),
                Text(
                  "Health Tip",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.refresh,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              _currentTip,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodCompatibilityCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Blood Type Compatibility",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Blood Type")),
                  DataColumn(label: Text("Can Donate To")),
                  DataColumn(label: Text("Can Receive From")),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text("A+")),
                    DataCell(Text("A+, AB+")),
                    DataCell(Text("A+, A-, O+, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("A-")),
                    DataCell(Text("A+, A-, AB+, AB-")),
                    DataCell(Text("A-, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("B+")),
                    DataCell(Text("B+, AB+")),
                    DataCell(Text("B+, B-, O+, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("B-")),
                    DataCell(Text("B+, B-, AB+, AB-")),
                    DataCell(Text("B-, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("AB+")),
                    DataCell(Text("AB+")),
                    DataCell(Text("All Types")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("AB-")),
                    DataCell(Text("AB+, AB-")),
                    DataCell(Text("A-, B-, AB-, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("O+")),
                    DataCell(Text("A+, B+, AB+, O+")),
                    DataCell(Text("O+, O-")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("O-")),
                    DataCell(Text("All Types")),
                    DataCell(Text("O-")),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, AuthService authService, bool isDark) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).navigationDrawerTheme.backgroundColor,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF2A2A2A), Color(0xFF1E1E1E)]
                      : [Color(0xFF6200EE), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'PulsePoint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.history,
              title: 'Activity History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.local_hospital,
              title: 'Nearby Hospitals',
              onTap: () {
                Navigator.pop(context);
                _findNearbyHospitals();
              },
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _findNearbyHospitals() async {
    setState(() {
      _isLoading = true;
      _locationMessage = '';
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _locationMessage = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _locationMessage =
              'Location permissions are permanently denied, cannot request permissions.';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Try to open maps with map_launcher package
      await _openMapsWithMapLauncher(position.latitude, position.longitude);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationMessage = 'Error: ${e.toString()}';
        print('Error finding hospitals: ${e.toString()}');
      });
    }
  }

  Future<void> _openMapsWithMapLauncher(
      double latitude, double longitude) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      print(
          'Available maps: ${availableMaps.map((e) => e.mapName).join(', ')}');

      if (availableMaps.isEmpty) {
        setState(() {
          _locationMessage = 'No map apps found on your device.';
        });
        return;
      }

      // Prefer Google Maps if available
      final googleMaps =
          availableMaps.where((map) => map.mapType == MapType.google).toList();

      if (googleMaps.isNotEmpty) {
        await googleMaps.first.showMarker(
          coords: Coords(latitude, longitude),
          title: "Your Location",
          description: "Hospitals near this location",
          extraParams: {
            'q': 'hospitals',
            'zoom': '14',
          },
        );
        setState(() {
          _locationMessage =
              'Showing nearby hospitals in ${googleMaps.first.mapName}';
        });
      } else {
        // If Google Maps is not available, show map selection dialog
        if (availableMaps.length == 1) {
          // If only one map is available, use it directly
          await availableMaps.first.showMarker(
            coords: Coords(latitude, longitude),
            title: "Your Location",
            description: "Hospitals near this location",
          );
          setState(() {
            _locationMessage =
                'Showing nearby hospitals in ${availableMaps.first.mapName}';
          });
        } else {
          // Let user select from multiple maps
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Choose Map App'),
                content: Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableMaps.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(availableMaps[index].mapName),
                        onTap: () async {
                          Navigator.pop(context);
                          await availableMaps[index].showMarker(
                            coords: Coords(latitude, longitude),
                            title: "Your Location",
                            description: "Hospitals near this location",
                          );
                          setState(() {
                            _locationMessage =
                                'Showing nearby hospitals in ${availableMaps[index].mapName}';
                          });
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error launching maps: ${e.toString()}';
      });
      print('Error launching maps: $e');

      // Fallback: try to launch with our custom method
      bool launched = await _legacyLaunchMaps(latitude, longitude, 'hospitals');
      if (launched) {
        setState(() {
          _locationMessage = 'Showing nearby hospitals';
        });
      } else {
        setState(() {
          _locationMessage =
              'Could not launch maps. Your coordinates are: $latitude, $longitude';
        });
      }
    }
  }

  // Keep this as a fallback method
  Future<bool> _legacyLaunchMaps(
      double latitude, double longitude, String query) async {
    String url = '';
    bool launched = false;

    // Try different approaches based on platform
    if (Platform.isAndroid) {
      // Try geo URI first (works with Google Maps)
      url = 'geo:$latitude,$longitude?q=$query';
      if (await canLaunchUrl(Uri.parse(url))) {
        launched = await launchUrl(Uri.parse(url));
        print('Tried launching with geo URI: $url, result: $launched');
        if (launched) return true;
      }

      // Try direct intent to Google Maps
      url = 'google.navigation:q=$query+near+$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(url))) {
        launched = await launchUrl(Uri.parse(url));
        print(
            'Tried launching with navigation intent: $url, result: $launched');
        if (launched) return true;
      }
    }

    // Try universal maps.google.com URL (works on most platforms and browsers)
    url = 'https://maps.google.com/?q=$query+near+$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      print('Tried launching maps.google.com: $url, result: $launched');
      if (launched) return true;
    }

    // Last resort: try a regular Google search
    url = 'https://www.google.com/search?q=$query+near+$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      print('Tried launching Google search: $url, result: $launched');
      if (launched) return true;
    }

    return false;
  }

  void _showEmergencyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.emergency, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    'Emergency Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildEmergencyButton(
                icon: Icons.phone,
                title: 'Call Emergency Services',
                onTap: () async {
                  Navigator.pop(context);
                  final call = Uri.parse('tel:108');
                  if (await canLaunchUrl(call)) {
                    launchUrl(call);
                  }
                },
              ),
              _buildEmergencyButton(
                icon: Icons.local_hospital,
                title: 'Nearby Hospitals',
                onTap: () {
                  Navigator.pop(context);
                  _findNearbyHospitals();
                },
              ),
              _buildEmergencyButton(
                icon: Icons.bloodtype,
                title: 'Request Blood Urgently',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BloodPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title),
      onTap: onTap,
      tileColor: Colors.red.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minLeadingWidth: 0,
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      mouseCursor: SystemMouseCursors.click,
    );
  }

  // Update user location
  Future<void> _updateUserLocation() async {
    LocationUtils.updateUserLocationSilently().then((success) {
      if (success) {
        print('User location updated from HomeScreen');
      }
    });
  }
}
