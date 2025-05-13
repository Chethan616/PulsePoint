import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  late TabController _tabController;
  bool _showBanner = true;

  // Cache for Lottie animations URLs to prevent reloading
  final Map<String, bool> _preloadedAnimations = {};

  // Cache for user data to reduce Firestore reads
  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _lastUserDataFetch;
  static const _userDataCacheTime = Duration(minutes: 5);

  // Sample achievement data - in a real app, this would come from the database
  final List<Map<String, dynamic>> achievements = [
    {
      'name': 'First Donation',
      'icon': Icons.volunteer_activism,
      'description': 'Completed your first blood donation',
      'unlocked': true,
      'date': DateTime.now().subtract(const Duration(days: 60)),
    },
    {
      'name': 'Regular Donor',
      'icon': Icons.repeat,
      'description': 'Donated blood 3 times',
      'unlocked': true,
      'date': DateTime.now().subtract(const Duration(days: 30)),
    },
    {
      'name': 'Lifesaver',
      'icon': Icons.favorite,
      'description': 'Helped save 5 lives through donations',
      'unlocked': false,
    },
    {
      'name': 'Community Hero',
      'icon': Icons.people,
      'description': 'Referred 3 friends to donate blood',
      'unlocked': false,
    },
  ];

  // Sample donation statistics - in a real app, this would be calculated from actual donation data
  final Map<String, dynamic> donationStats = {
    'totalDonations': 3,
    'livesImpacted': 9,
    'lastDonation': DateTime.now().subtract(const Duration(days: 45)),
    'nextEligibleDate': DateTime.now().add(const Duration(days: 45)),
  };

  // Cached widgets for performance
  final Widget _loadingIndicator = const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(),
        ),
        SizedBox(height: 16),
        Text('Loading profile...'),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();

    // Pre-load commonly used animations
    _preloadAnimations();
  }

  void _preloadAnimations() {
    _preloadedAnimations['health_check'] = true;
    _preloadedAnimations['loading'] = true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    // Show loading while we fetch data
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Check if we can use cached data (if it's recent enough)
        final bool useCache = _cachedUserData != null &&
            _lastUserDataFetch != null &&
            DateTime.now().difference(_lastUserDataFetch!) < _userDataCacheTime;

        if (useCache) {
          // Use cached data
          setState(() {
            userData = _cachedUserData;
            _isLoading = false;
          });
          return;
        }

        // Fetch fresh data from Firestore
        final DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!mounted) return;

        // Cache the user data
        _cachedUserData = doc.data() as Map<String, dynamic>?;
        _lastUserDataFetch = DateTime.now();

        // Update UI
        setState(() {
          userData = _cachedUserData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileAvatar() {
    final profileImageUrl = userData?['profileImageUrl'] as String?;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.secondary.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            backgroundImage:
                profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profileImageUrl)
                    : null,
            child: profileImageUrl == null || profileImageUrl.isEmpty
                ? Text(
                    userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 50,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // Show edit options
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile picture update coming soon!')),
                );
              },
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value,
      {bool isPhone = false, bool isEditable = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showEditDialog(title, value);
                },
              ),
            if (isPhone)
              IconButton(
                icon: Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Could not launch dialer. Please check your device settings."),
        ),
      );
    }
  }

  Widget _buildAchievementTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isUnlocked = achievement['unlocked'] as bool;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'] as IconData,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : isDark
                          ? Colors.grey[600]
                          : Colors.grey[400],
                ),
              ),
              title: Text(
                achievement['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? null
                      : isDark
                          ? Colors.grey[500]
                          : Colors.grey[500],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    achievement['description'] as String,
                    style: TextStyle(
                      color: isUnlocked
                          ? null
                          : isDark
                              ? Colors.grey[600]
                              : Colors.grey[600],
                    ),
                  ),
                  if (isUnlocked && achievement.containsKey('date'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Unlocked: ${DateFormat('MMM d, yyyy').format(achievement['date'])}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: isUnlocked
                  ? Icon(Icons.verified, color: Colors.green)
                  : Icon(Icons.lock_outline, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Donation stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Donations",
                  donationStats['totalDonations'].toString(),
                  Icons.bloodtype,
                  colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Lives Impacted",
                  donationStats['livesImpacted'].toString(),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Last donation & next eligibility
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Donation Timeline",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTimelineItem(
                    "Last Donation",
                    DateFormat('MMM d, yyyy')
                        .format(donationStats['lastDonation']),
                    Icons.history,
                    Colors.blue,
                  ),
                  SizedBox(height: 16),
                  _buildTimelineItem(
                    "Next Eligible Date",
                    DateFormat('MMM d, yyyy')
                        .format(donationStats['nextEligibleDate']),
                    Icons.event_available,
                    Colors.green,
                  ),

                  // Blood donation eligibility progress
                  SizedBox(height: 24),
                  Text(
                    "Eligibility Progress",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _calculateEligibilityProgress(),
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _calculateEligibilityProgress() >= 1.0
                          ? Colors.green
                          : Colors.orange,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _calculateEligibilityProgress() >= 1.0
                        ? "You're eligible to donate again!"
                        : "You'll be eligible in ${_getDaysUntilEligible()} days",
                    style: TextStyle(
                      fontSize: 14,
                      color: _calculateEligibilityProgress() >= 1.0
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Blood donation tips
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "Donation Tips",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTipItem("Stay hydrated before and after donation"),
                  _buildTipItem(
                      "Eat iron-rich foods to maintain healthy hemoglobin levels"),
                  _buildTipItem(
                      "Avoid heavy lifting for 24 hours after donation"),
                  _buildTipItem("Rest well the night before donation"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(tip),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String date, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateEligibilityProgress() {
    final lastDonation = donationStats['lastDonation'] as DateTime;
    final nextEligible = donationStats['nextEligibleDate'] as DateTime;
    final totalDays = nextEligible.difference(lastDonation).inDays;
    final daysPassed = DateTime.now().difference(lastDonation).inDays;

    return daysPassed / totalDays;
  }

  int _getDaysUntilEligible() {
    final nextEligible = donationStats['nextEligibleDate'] as DateTime;
    return nextEligible.difference(DateTime.now()).inDays;
  }

  Widget _buildProfileTab() {
    if (userData == null) {
      return Center(child: Text('No user data available'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health banner for next blood test
          if (_showBanner) _buildHealthBanner(),

          SizedBox(height: 16),
          _buildInfoCard(
            Icons.person,
            'Full Name',
            userData!['name'] ?? 'Not set',
            isEditable: true,
          ),
          SizedBox(height: 12),
          _buildInfoCard(
            Icons.phone,
            'Phone Number',
            _auth.currentUser?.phoneNumber ?? 'Not set',
          ),
          SizedBox(height: 12),
          _buildInfoCard(
            Icons.favorite,
            'Blood Type',
            userData!['bloodType'] ?? 'Not set',
          ),
          SizedBox(height: 12),

          // Fixed height and weight cards with better layout
          _buildPhysicalInfoCard(),

          SizedBox(height: 12),
          _buildInfoCard(
            Icons.location_on,
            'Location',
            userData!['zipCode'] ?? 'Not set',
            isEditable: true,
          ),
          if (userData!.containsKey('healthAddictions') &&
              userData!['healthAddictions'] != null &&
              userData!['healthAddictions'].toString().isNotEmpty)
            Column(
              children: [
                SizedBox(height: 12),
                _buildInfoCard(
                  Icons.health_and_safety,
                  'Health Information',
                  userData!['healthAddictions'],
                  isEditable: true,
                ),
              ],
            ),
          SizedBox(height: 24),

          // Delete account button
          Center(
            child: TextButton.icon(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Delete Account?'),
                      content: Text(
                        'This action cannot be undone. All your data will be permanently deleted.',
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            // TODO: Implement account deletion
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Account deletion is not implemented yet.'),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    const healthCheckAnimation =
        'https://assets6.lottiefiles.com/packages/lf20_wgkcbvt0.json';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to schedule or show modal
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scheduling feature coming soon!')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Lottie.network(
                    healthCheckAnimation,
                    fit: BoxFit.contain,
                    frameRate: FrameRate.max,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.health_and_safety_outlined,
                        size: 40,
                        color: isDark
                            ? colorScheme.primary
                            : const Color(0xFFFF5F6D),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time for a health check!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Schedule your next blood test to ensure you're ready for donation",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _showBanner = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final height = userData!['height'] ?? 'N/A';
    final weight = userData!['weight'] ?? 'N/A';
    final bool hasBoth = height != 'N/A' && weight != 'N/A';

    // Calculate BMI if both height and weight are available
    double? bmi;
    String bmiCategory = '';
    Color bmiColor = Colors.grey;

    if (hasBoth) {
      try {
        double heightValue = double.parse(height.toString());
        double weightValue = double.parse(weight.toString());
        bmi = weightValue / ((heightValue / 100) * (heightValue / 100));

        if (bmi < 18.5) {
          bmiCategory = 'Underweight';
          bmiColor = Colors.blue;
        } else if (bmi >= 18.5 && bmi < 25) {
          bmiCategory = 'Normal';
          bmiColor = Colors.green;
        } else if (bmi >= 25 && bmi < 30) {
          bmiCategory = 'Overweight';
          bmiColor = Colors.orange;
        } else {
          bmiCategory = 'Obese';
          bmiColor = Colors.red;
        }
      } catch (e) {
        print('Error calculating BMI: $e');
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: colorScheme.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Physical Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, size: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showPhysicalInfoEditDialog(height, weight);
                  },
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPhysicalInfoItem(
                    Icons.height,
                    'Height',
                    height != 'N/A' ? '$height cm' : 'Not set',
                    colorScheme.primary,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                Expanded(
                  child: _buildPhysicalInfoItem(
                    Icons.monitor_weight,
                    'Weight',
                    weight != 'N/A' ? '$weight kg' : 'Not set',
                    colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (bmi != null) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, color: bmiColor, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'BMI: ${bmi.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bmiColor, width: 1),
                    ),
                    child: Text(
                      bmiCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: bmiColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalInfoItem(
      IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPhysicalInfoEditDialog(
      dynamic currentHeight, dynamic currentWeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Create controllers for height and weight
    final heightController = TextEditingController(
        text: currentHeight != 'N/A' ? currentHeight.toString() : '');

    final weightController = TextEditingController(
        text: currentWeight != 'N/A' ? currentWeight.toString() : '');

    // State variables for validation
    bool heightError = false;
    bool weightError = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          // Validation function
          void validateInputs() {
            setState(() {
              if (heightController.text.isNotEmpty) {
                final height = double.tryParse(heightController.text);
                heightError = height == null || height < 50 || height > 250;
              } else {
                heightError = false;
              }

              if (weightController.text.isNotEmpty) {
                final weight = double.tryParse(weightController.text);
                weightError = weight == null || weight < 20 || weight > 250;
              } else {
                weightError = false;
              }
            });
          }

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            title: const Text('Edit Physical Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => validateInputs(),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'Enter your height',
                    suffixText: 'cm',
                    errorText:
                        heightError ? 'Enter a valid height (50-250 cm)' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => validateInputs(),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your weight',
                    suffixText: 'kg',
                    errorText:
                        weightError ? 'Enter a valid weight (20-250 kg)' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? colorScheme.primary : const Color(0xFFFF5F6D),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // Validate again before submitting
                  validateInputs();
                  if (heightError || weightError) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fix the errors before saving')));
                    return;
                  }

                  HapticFeedback.mediumImpact();

                  // Get values - convert empty strings to null
                  final height = heightController.text.isEmpty
                      ? null
                      : heightController.text.trim();
                  final weight = weightController.text.isEmpty
                      ? null
                      : weightController.text.trim();

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  try {
                    // Update Firestore
                    User? user = _auth.currentUser;
                    if (user != null) {
                      final batch = _firestore.batch();
                      final userRef =
                          _firestore.collection('users').doc(user.uid);

                      // Use batch write for better performance
                      batch.update(userRef, {
                        'height': height,
                        'weight': weight,
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });

                      await batch.commit();

                      // Update cache
                      if (_cachedUserData != null) {
                        _cachedUserData!['height'] = height;
                        _cachedUserData!['weight'] = weight;
                      }

                      // Reload user data
                      await _loadUserData();

                      // Close loading dialog and edit dialog
                      Navigator.pop(context);
                      Navigator.pop(context);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Physical information updated successfully')),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    Navigator.pop(context);

                    print("Error updating physical information: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Error updating physical information: $e')),
                    );

                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  // Add edit dialog method
  void _showEditDialog(String field, String currentValue) {
    final TextEditingController editController = TextEditingController(
        text: currentValue != 'Not set' ? currentValue : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine field type
    TextInputType keyboardType = TextInputType.text;
    String fieldKey = '';
    String hintText = '';
    String? suffixText;

    switch (field) {
      case 'Full Name':
        keyboardType = TextInputType.name;
        fieldKey = 'name';
        hintText = 'Enter your full name';
        break;
      case 'Height':
        keyboardType = TextInputType.number;
        fieldKey = 'height';
        hintText = 'Enter your height';
        suffixText = 'cm';
        // Clean the current value
        if (currentValue.contains('cm')) {
          editController.text =
              currentValue.replaceAll(' cm', '').replaceAll('Not set', '');
        }
        break;
      case 'Weight':
        keyboardType = TextInputType.number;
        fieldKey = 'weight';
        hintText = 'Enter your weight';
        suffixText = 'kg';
        // Clean the current value
        if (currentValue.contains('kg')) {
          editController.text =
              currentValue.replaceAll(' kg', '').replaceAll('Not set', '');
        }
        break;
      case 'Location':
        keyboardType = TextInputType.streetAddress;
        fieldKey = 'zipCode';
        hintText = 'Enter your location';
        break;
      case 'Health Information':
        keyboardType = TextInputType.multiline;
        fieldKey = 'healthAddictions';
        hintText = 'Enter health information';
        break;
      default:
        return; // Unknown field
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Color(0xFF1F1F1F) : Colors.white,
          title: Text('Edit $field'),
          content: TextField(
            controller: editController,
            keyboardType: keyboardType,
            maxLines: fieldKey == 'healthAddictions' ? 3 : 1,
            decoration: InputDecoration(
              hintText: hintText,
              suffixText: suffixText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();

                // Validate input if needed
                if (editController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid value')),
                  );
                  return;
                }

                // Update Firestore
                try {
                  User? user = _auth.currentUser;
                  if (user != null) {
                    await _firestore.collection('users').doc(user.uid).update({
                      fieldKey: editController.text,
                    });

                    // Reload user data
                    await _loadUserData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$field updated successfully')),
                    );
                  }
                } catch (e) {
                  print("Error updating profile: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
            tooltip: 'Toggle theme',
            onPressed: () {
              HapticFeedback.lightImpact();
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? _loadingIndicator
          : Column(
              children: [
                // Profile header with const where possible
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E1E1E),
                              colorScheme.primary.withOpacity(0.3)
                            ]
                          : [
                              colorScheme.primary.withOpacity(0.7),
                              colorScheme.primary
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(height: 12),
                        Text(
                          userData?['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData?['bloodType'] ?? 'Blood Type Not Set',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Profile', icon: Icon(Icons.person)),
                    Tab(text: 'Stats', icon: Icon(Icons.bar_chart)),
                    Tab(text: 'Achievements', icon: Icon(Icons.emoji_events)),
                  ],
                  labelColor: colorScheme.primary,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : Colors.black54,
                  indicatorColor: colorScheme.primary,
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildStatsTab(),
                      _buildAchievementTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
