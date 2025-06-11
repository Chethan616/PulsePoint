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
import 'package:url_launcher/url_launcher.dart';
import 'package:pulsepoint/widgets/star_rating.dart';
import 'package:pulsepoint/utilities/rating_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtherProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  OtherProfileScreen({required this.userData});

  @override
  _OtherProfileScreenState createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  bool _hasRated = false;
  double _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _checkIfOwnProfile();
    _checkIfUserHasRated();
  }

  void _checkIfOwnProfile() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.userData['uid'] == currentUser.uid) {
      setState(() {
        _isOwnProfile = true;
      });
    }
  }

  Future<void> _checkIfUserHasRated() async {
    // Don't bother checking if it's own profile
    if (_isOwnProfile) return;

    // Ensure we have a valid user ID
    final userId = widget.userData['uid'] ?? '';
    if (userId.isEmpty) {
      print("Warning: User ID is empty, can't check rating status");
      return;
    }

    final hasRated = await RatingUtils.hasUserRated(userId);

    if (mounted) {
      setState(() {
        _hasRated = hasRated;
      });
    }
  }

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
            SizedBox(height: 8),
            Text(
              userData['name'],
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            // Display user rating only if not own profile
            if (!_isOwnProfile)
              RatingDisplay(
                rating: userData['averageRating']?.toDouble() ?? 0.0,
                totalRatings: userData['totalRatings'] ?? 0,
                starSize: 20,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Ensure we have a valid user ID
    final userId = widget.userData['uid'] ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Cannot identify user to rate')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      final success = await RatingUtils.rateUser(
        recipientUserId: userId,
        rating: _selectedRating,
        comment: _commentController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted successfully')),
        );
        setState(() {
          _hasRated = true;
          _isSubmitting = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildRatingSection() {
    // Don't show rating section if it's the user's own profile
    if (_isOwnProfile) {
      return SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_hasRated) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'You have already rated this user',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
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
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rate this user',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              Center(
                child: Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: StarRating(
                  rating: _selectedRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  size: 40,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Add a comment (optional)',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
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
        title: Text(_isOwnProfile
            ? 'My Profile'
            : 'Profile of ${widget.userData['name']}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(widget.userData),
            _buildRatingSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    Icons.phone,
                    'Phone Number',
                    widget.userData['phoneNumber'] ?? 'N/A',
                    isPhone: true,
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    Icons.favorite,
                    'Blood Type',
                    widget.userData['bloodType'] ?? 'N/A',
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.height,
                          'Height',
                          '${widget.userData['height'] ?? 'N/A'} ${widget.userData['height'] != null ? 'cm' : ''}',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.monitor_weight,
                          'Weight',
                          '${widget.userData['weight'] ?? 'N/A'} ${widget.userData['weight'] != null ? 'kg' : ''}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (widget.userData['healthAddictions'] != null &&
                      widget.userData['healthAddictions'].toString().isNotEmpty)
                    Column(
                      children: [
                        _buildInfoCard(
                          Icons.healing,
                          'Health Information',
                          widget.userData['healthAddictions'],
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
