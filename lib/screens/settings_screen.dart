import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsepoint_v2/app_preferences_screens/contact_us_screen.dart';
import 'package:pulsepoint_v2/app_preferences_screens/linked_in_screen.dart';
import 'package:pulsepoint_v2/app_preferences_screens/privacy_policy_screen.dart';
import 'package:pulsepoint_v2/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/providers/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  late User _currentUser;
  late CollectionReference _usersCollection;
  Map<String, dynamic>? userData;

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadUserData();
  }

  void _initializeFirebase() {
    try {
      _currentUser = FirebaseAuth.instance.currentUser!;
      _usersCollection = FirebaseFirestore.instance.collection('users');
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  Widget _buildProfileAvatar() {
    final profileImageUrl = userData?['profileImageUrl'] as String?;

    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl == null || profileImageUrl.isEmpty
          ? Text(
              userData?['name'][0] ?? 'U',
              style: TextStyle(
                fontSize: 40,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return _buildErrorScreen('User not authenticated');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(
                color: Colors.blue[800], fontWeight: FontWeight.w800)),
        backgroundColor: Colors.lightBlue[100],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[00]),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.lightBlue[100]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _usersCollection.doc(_currentUser.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            if (snapshot.hasError) {
              return _buildErrorScreen('Error loading user data');
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildErrorScreen('User data not found');
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final bloodType = _getBloodType(userData);

            return _buildMainContent(userData, bloodType);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> userData, String bloodType) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(userData, bloodType),
          _buildSectionTitle('Preferences'),
          _buildDarkModeSwitch(),
          _buildLanguageSelector(),
          _buildNotificationSwitch(),
          _buildSectionTitle('Support'),
          _buildSupportCard(),
          _buildSectionTitle('About'),
          _buildAppInfo(),
          _buildLogoutButton(context),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData, String bloodType) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _buildProfileAvatar(),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData['name']?.toString() ?? 'Anonymous User',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 8),
              _buildBloodTypeTag(bloodType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeTag(String bloodType) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.lightBlue[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.lightBlue[400]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.blue[800], size: 16),
          SizedBox(width: 6),
          Text(
            'Blood Type: $bloodType',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getBloodType(Map<String, dynamic> userData) {
    const defaultBloodType = 'Not Specified';
    final bloodType = userData['bloodType']?.toString()?.toUpperCase();

    final validBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    return bloodType != null && validBloodTypes.contains(bloodType)
        ? bloodType
        : defaultBloodType;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[800]),
          SizedBox(height: 20),
          Text('Loading user data...',
              style: TextStyle(color: Colors.blue[800])),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeSwitch() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: SwitchListTile(
        title: Text('Dark Mode', style: TextStyle(color: Colors.blue[800])),
        secondary: Icon(Icons.nightlight_round, color: Colors.purple),
        value: _darkMode,
        onChanged: (value) {
          setState(() {
            _darkMode = value;
          });
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: ListTile(
        leading: Icon(Icons.language, color: Colors.blue[800]),
        title: Text('Language', style: TextStyle(color: Colors.blue[800])),
        trailing: DropdownButton<String>(
          dropdownColor: Colors.white,
          value: _selectedLanguage,
          underline: Container(),
          items: ['English', 'Spanish', 'French', 'German']
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child:
                        Text(lang, style: TextStyle(color: Colors.blue[800])),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: SwitchListTile(
        title: Text('Notifications', style: TextStyle(color: Colors.blue[800])),
        secondary: Icon(Icons.notifications_active, color: Colors.orange[800]),
        value: _notificationsEnabled,
        onChanged: (value) {
          setState(() {
            _notificationsEnabled = value;
          });
        },
      ),
    );
  }

  Widget _buildSupportCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.white,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.link_rounded, color: Colors.green),
              title: Text('Our LinkedIn',
                  style: TextStyle(color: Colors.blue[800])),
              trailing: Icon(Icons.chevron_right, color: Colors.blue[800]),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LinkedInSection()),
              ),
            ),
            Divider(height: 0, color: Colors.grey[200]),
            ListTile(
              leading: Icon(Icons.contact_support, color: Colors.red),
              title:
                  Text('Contact Us', style: TextStyle(color: Colors.blue[800])),
              trailing: Icon(Icons.chevron_right, color: Colors.blue[800]),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsPage()),
              ),
            ),
            Divider(height: 0, color: Colors.grey[200]),
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.lightBlue),
              title: Text('Privacy Policy',
                  style: TextStyle(color: Colors.blue[800])),
              trailing: Icon(Icons.chevron_right, color: Colors.blue[800]),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.white,
        child: ListTile(
          leading: Icon(Icons.info_outline, color: Colors.purple),
          title: Text('About App', style: TextStyle(color: Colors.blue[800])),
          subtitle:
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
          trailing: Icon(Icons.chevron_right, color: Colors.blue[800]),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'PulsePoint',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025 PulsePoint Health Inc.',
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Padding(
      padding: EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(double.infinity, 50),
        ),
        onPressed: () async {
          try {
            await authService.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logout failed: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            print('Logout error: $e');
          }
        },
        child: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
