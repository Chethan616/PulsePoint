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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pulsepoint/app_preferences_screens/contact_us_screen.dart';
import 'package:pulsepoint/app_preferences_screens/linked_in_screen.dart';
import 'package:pulsepoint/app_preferences_screens/privacy_policy_screen.dart';
import 'package:pulsepoint/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint/providers/auth_service.dart';
import 'package:pulsepoint/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:pulsepoint/screens/widgets_settings_screen.dart';
import 'package:pulsepoint/screens/widget_debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final profileImageUrl = userData?['profileImageUrl'] as String?;

    return CircleAvatar(
      radius: 40,
      backgroundColor: isDark
          ? colorScheme.primary.withOpacity(0.2)
          : colorScheme.secondary.withOpacity(0.2),
      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl == null || profileImageUrl.isEmpty
          ? Text(
              userData?['name']?[0].toUpperCase() ?? 'U',
              style: TextStyle(
                fontSize: 40,
                color: isDark ? colorScheme.primary : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    if (_auth.currentUser == null) {
      return _buildErrorScreen('User not authenticated');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                  ]
                : [
                    Color(0xFFFF5F6D).withOpacity(0.9),
                    Color(0xFFFFC371).withOpacity(0.8),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(userData, bloodType),
          SizedBox(height: 10),
          _buildSettingsSection(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData, String bloodType) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProfileAvatar(),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name']?.toString() ?? 'Anonymous User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildBloodTypeTag(bloodType),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            icon: Icon(Icons.edit),
            label: Text('Edit Profile'),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showEditProfileModal(userData);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? colorScheme.primary : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(Map<String, dynamic> userData) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Create controllers for each field
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final heightController =
        TextEditingController(text: userData['height']?.toString() ?? '');
    final weightController =
        TextEditingController(text: userData['weight']?.toString() ?? '');
    final zipCodeController =
        TextEditingController(text: userData['zipCode'] ?? '');
    final bloodTypeController =
        TextEditingController(text: userData['bloodType'] ?? '');
    final healthAddictionsController =
        TextEditingController(text: userData['healthAddictions'] ?? '');

    // Blood type options
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String selectedBloodType = userData['bloodType'] ?? bloodTypes[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1F1F1F) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Header with drag handle
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Divider(),

                // Profile photo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: GestureDetector(
                    onTap: () => _updateProfilePhoto(),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            _buildProfileAvatar(),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.primary
                                      : Color(0xFFFF5F6D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Color(0xFF1F1F1F)
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Change Photo',
                          style: TextStyle(
                            color: isDark
                                ? colorScheme.primary
                                : Color(0xFFFF5F6D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form fields in scrollview
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField('Full Name', nameController, isDark),
                        SizedBox(height: 16),
                        Text(
                          'Blood Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF2A2A2A)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBloodType,
                              isExpanded: true,
                              dropdownColor:
                                  isDark ? Color(0xFF2A2A2A) : Colors.white,
                              items: bloodTypes.map((String bloodType) {
                                return DropdownMenuItem<String>(
                                  value: bloodType,
                                  child: Text(bloodType),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedBloodType = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                  'Height (cm)', heightController, isDark,
                                  keyboardType: TextInputType.number),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                  'Weight (kg)', weightController, isDark,
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildFormField('Location', zipCodeController, isDark),
                        SizedBox(height: 16),
                        _buildFormField('Health Information (Optional)',
                            healthAddictionsController, isDark,
                            maxLines: 3),
                      ],
                    ),
                  ),
                ),

                // Save button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();

                      // Validate form
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter your name')),
                        );
                        return;
                      }

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        // Update firestore
                        await _firestore
                            .collection('users')
                            .doc(_currentUser.uid)
                            .update({
                          'name': nameController.text,
                          'bloodType': selectedBloodType,
                          'height': heightController.text.isEmpty
                              ? null
                              : heightController.text,
                          'weight': weightController.text.isEmpty
                              ? null
                              : weightController.text,
                          'zipCode': zipCodeController.text,
                          'healthAddictions': healthAddictionsController.text,
                        });

                        // Reload user data
                        await _loadUserData();

                        // Close loading dialog
                        Navigator.pop(context);

                        // Close edit dialog
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Profile updated successfully')),
                        );
                      } catch (e) {
                        // Close loading dialog
                        Navigator.pop(context);

                        print("Error updating profile: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating profile: $e')),
                        );
                      }
                    },
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildFormField(
      String label, TextEditingController controller, bool isDark,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Color(0xFF6A60F0) : Color(0xFFFF5F6D),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfilePhoto() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    // Show options dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Color(0xFF1F1F1F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_camera,
                      color: isDark ? Color(0xFF6A60F0) : Color(0xFFFF5F6D)),
                  title: Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library,
                      color: isDark ? Color(0xFF6A60F0) : Color(0xFFFF5F6D)),
                  title: Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (userData?['profileImageUrl'] != null) ...[
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Remove current photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Create storage reference and upload file
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_currentUser.uid}.jpg');

      await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore with new image URL
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // Reload user data
      await _loadUserData();

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo updated successfully')),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      // Delete file from storage if it exists
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${_currentUser.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        // Ignore if file doesn't exist
        print('Storage delete error (might be ok): $e');
      }

      // Remove URL from Firestore
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'profileImageUrl': null,
      });

      // Reload user data
      await _loadUserData();

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo removed')),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error removing profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing profile photo: $e')),
      );
    }
  }

  Widget _buildBloodTypeTag(String bloodType) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primary.withOpacity(0.2)
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? colorScheme.primary : colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bloodtype,
            color: isDark ? colorScheme.primary : colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'Blood Type: $bloodType',
            style: TextStyle(
              color: isDark ? colorScheme.primary : colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preferences section
          _buildSectionHeader('Preferences', Icons.settings),
          _buildDarkModeSwitch(),
          _buildLanguageSelector(),
          _buildNotificationSwitch(),
          _buildSection(
            title: 'Widgets',
            children: [
              _buildSettingTile(
                title: 'Home Screen Widgets',
                subtitle: 'Configure and preview home screen widgets',
                icon: Icons.widgets,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WidgetsSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                title: 'Widget Troubleshooter',
                subtitle: 'Debug and fix issues with home screen widgets',
                icon: Icons.bug_report,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WidgetDebugScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // Support section
          _buildSectionHeader('Support & Information', Icons.help_outline),
          _buildSupportItem(
            'Our LinkedIn',
            Icons.link_rounded,
            isDark ? Colors.cyan : Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LinkedInSection()),
            ),
          ),
          _buildSupportItem(
            'Contact Us',
            Icons.contact_support,
            isDark ? Colors.orange : Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactUsPage()),
            ),
          ),
          _buildSupportItem(
            'Privacy Policy',
            Icons.privacy_tip,
            isDark ? Colors.green : Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
            ),
          ),
          _buildSupportItem(
            'About App',
            Icons.info_outline,
            isDark ? Colors.purple : Colors.deepPurple,
            () {
              showAboutDialog(
                context: context,
                applicationName: 'PulsePoint',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 PulsePoint Health Inc.',
              );
            },
            subtitle: 'Version 1.0.0',
          ),

          SizedBox(height: 20),
          _buildLogoutButton(context),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? colorScheme.primary : colorScheme.primary,
            size: 22,
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
      onTap: onTap,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? colorScheme.primary : colorScheme.primary,
          ),
          SizedBox(height: 20),
          Text(
            'Loading user data...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.white,
            ),
          ),
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

  Widget _buildDarkModeSwitch() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      title: Text('Dark Mode'),
      subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
      secondary: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? colorScheme.primary : colorScheme.primary,
        ),
      ),
      value: themeProvider.isDarkMode,
      onChanged: (value) {
        themeProvider.toggleTheme();
      },
      activeColor: isDark ? colorScheme.primary : colorScheme.primary,
    );
  }

  Widget _buildLanguageSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.blue.withOpacity(0.2)
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.language,
          color: Colors.blue,
        ),
      ),
      title: Text('Language'),
      subtitle: Text(_selectedLanguage),
      trailing: DropdownButton<String>(
        dropdownColor: isDark ? Color(0xFF1F1F1F) : Colors.white,
        value: _selectedLanguage,
        underline: Container(),
        items: ['English', 'Spanish', 'French', 'German']
            .map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
        },
      ),
    );
  }

  Widget _buildNotificationSwitch() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      title: Text('Notifications'),
      subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
      secondary: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.amber.withOpacity(0.2)
              : Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: Colors.amber,
        ),
      ),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
        });
      },
      activeColor: isDark ? colorScheme.primary : colorScheme.primary,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? Colors.deepPurple : Colors.purple),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
      onTap: onTap,
    );
  }
}

