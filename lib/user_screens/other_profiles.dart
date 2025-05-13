import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  OtherProfileScreen({required this.userData});

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  Widget _buildInfoCard(IconData icon, String title, String value,
      {bool isPhone = false}) {
    return GestureDetector(
      onTap: isPhone && value != 'N/A' ? () => _makePhoneCall(value) : null,
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
                      color: isPhone ? Colors.blue : Colors.black,
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

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
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
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: userData['profileImageUrl'] != null &&
                      userData['profileImageUrl'].isNotEmpty
                  ? NetworkImage(userData['profileImageUrl'])
                  : NetworkImage(
                      'https://img.freepik.com/free-photo/abstract-surface-textures-white-concrete-stone-wall_74190-8189.jpg?t=st=1738665301~exp=1738668901~hmac=aed49d0e26cf7e9f1caa3fc2910c22b5eb47db0eb71f7da81578bbf8a0c357dc&w=1380',
                    ) as ImageProvider,
              child: userData['profileImageUrl'] == null ||
                      userData['profileImageUrl'].isEmpty
                  ? Text(
                      userData['name'][0],
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              userData['name'],
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile of ${userData['name']}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(userData),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    Icons.phone,
                    'Phone Number',
                    userData['phoneNumber'] ?? 'N/A',
                    isPhone: true,
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    Icons.favorite,
                    'Blood Type',
                    userData['bloodType'] ?? 'N/A',
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.height,
                          'Height',
                          '${userData['height']} cm',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.monitor_weight,
                          'Weight',
                          '${userData['weight']} kg',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (userData['healthAddictions'] != null &&
                      userData['healthAddictions'].toString().isNotEmpty)
                    Column(
                      children: [
                        _buildInfoCard(
                          Icons.healing,
                          'Health Information',
                          userData['healthAddictions'],
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
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
