import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    print("Cleaned Phone Number: $cleanedNumber"); // Debug log

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
    print("Phone URI: $phoneUri"); // Debug log

    if (await canLaunchUrl(phoneUri)) {
      print("Launching dialer..."); // Debug log
      await launchUrl(phoneUri);
    } else {
      print("Failed to launch dialer"); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Could not launch dialer. Please check your device settings.")),
      );
    }
  }

  Widget _buildInfoCard(IconData icon, String title, String value,
      {bool isPhone = false}) {
    return GestureDetector(
      onTap: isPhone
          ? () {
              // showDialog(
              //   context: context,
              //   builder: (BuildContext context) {
              //     return AlertDialog(
              //       title: Text("Call User"),
              //       content: Text("Do you want to call $value?"),
              //       actions: [
              //         TextButton(
              //           child: Text("Cancel"),
              //           onPressed: () => Navigator.pop(context),
              //         ),
              //         TextButton(
              //           child: Text("Call"),
              //           onPressed: () {
              //             Navigator.pop(context);
              //             _makePhoneCall(value);
              //           },
              //         ),
              //       ],
              //     );
              //   },
              // );
            }
          : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.logout),
          //   onPressed: () => _auth.signOut(),
          // ),
        ],
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[800]!, Colors.blue[400]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileAvatar(),
                          SizedBox(height: 16),
                          Text(
                            userData!['name'],
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          Icons.phone,
                          'Phone Number',
                          _auth.currentUser?.phoneNumber ?? 'N/A',
                          isPhone: true,
                        ),
                        SizedBox(height: 16),
                        _buildInfoCard(
                          Icons.favorite,
                          'Blood Type',
                          userData!['bloodType'] ?? 'N/A',
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                Icons.height,
                                'Height',
                                '${userData!['height']} cm',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.monitor_weight,
                                'Weight',
                                '${userData!['weight']} kg',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Thank you for being a life saver! ❤️',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
