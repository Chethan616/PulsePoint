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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulsepoint/user_screens/other_profiles.dart';
import 'package:pulsepoint/utilities/location_utils.dart';

class ReceiveBloodScreen extends StatefulWidget {
  @override
  _ReceiveBloodScreenState createState() => _ReceiveBloodScreenState();
}

class _ReceiveBloodScreenState extends State<ReceiveBloodScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Position? _currentUserPosition;
  Map<String, dynamic>? _currentUserData;

  // Filter variables
  String? _selectedBloodType;
  String? _selectedGender;
  double _maxDistance = 50; // in kilometers
  int? _minAge;
  int? _maxAge;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserData = userDoc.data() as Map<String, dynamic>;
          if (_currentUserData?['location'] != null) {
            _currentUserPosition = Position(
              latitude: _currentUserData!['location']['latitude'],
              longitude: _currentUserData!['location']['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0.0, // Providing a value
              altitude: 0.0, // Providing a value
              altitudeAccuracy: 0.0, // Providing a value
              heading: 0.0, // Providing a value
              headingAccuracy: 0.0, // Providing a value
              speed: 0.0, // Providing a value
              speedAccuracy: 0.0, // Providing a value
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Blood Donors'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, blood type, or zip code...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          _buildActiveFiltersChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                List<QueryDocumentSnapshot> users = snapshot.data!.docs;
                List<QueryDocumentSnapshot> filteredUsers = users.where((user) {
                  Map<String, dynamic> data =
                      user.data() as Map<String, dynamic>;
                  return _matchesSearch(data) && _matchesFilters(data);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    return _buildDonorCard(userData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    List<Widget> chips = [];
    if (_selectedBloodType != null) {
      chips.add(Chip(
        label: Text('Blood: $_selectedBloodType'),
        onDeleted: () => setState(() => _selectedBloodType = null),
      ));
    }
    if (_selectedGender != null) {
      chips.add(Chip(
        label: Text('Gender: $_selectedGender'),
        onDeleted: () => setState(() => _selectedGender = null),
      ));
    }
    if (_currentUserPosition != null) {
      chips.add(Chip(
        label: Text('Within ${_maxDistance.round()}km'),
        onDeleted: () => setState(() => _maxDistance = 50),
      ));
    }
    if (_minAge != null || _maxAge != null) {
      chips.add(Chip(
        label: Text('Age: ${_minAge ?? ''}-${_maxAge ?? ''}'),
        onDeleted: () => setState(() {
          _minAge = null;
          _maxAge = null;
        }),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> userData) {
    double? distance =
        _currentUserPosition != null && userData['location'] != null
            ? calculateDistance(
                _currentUserPosition!.latitude,
                _currentUserPosition!.longitude,
                userData['location']['latitude'],
                userData['location']['longitude'],
              )
            : null;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: userData['profileImageUrl'] != null &&
                      userData['profileImageUrl'].isNotEmpty
                  ? NetworkImage(userData['profileImageUrl'])
                  : null,
              child: userData['profileImageUrl'] == null ||
                      userData['profileImageUrl'].isEmpty
                  ? Icon(Icons.person_2_rounded,
                      size: 30, color: Colors.blueGrey)
                  : null,
            ),
            SizedBox(width: 16),

            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Blood Type
                  Row(
                    children: [
                      Text(
                        userData['name'] ?? 'Anonymous',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          userData['bloodType'] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Age and Gender
                  if (userData['age'] != null || userData['gender'] != null)
                    Row(
                      children: [
                        if (userData['age'] != null)
                          Text('${userData['age']} years'),
                        if (userData['age'] != null &&
                            userData['gender'] != null)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child:
                                Text('•', style: TextStyle(color: Colors.grey)),
                          ),
                        if (userData['gender'] != null)
                          Text(userData['gender']),
                      ],
                    ),

                  // Distance and Location
                  if (distance != null ||
                      userData['location']?['zipCode'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (distance != null)
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('${distance.toStringAsFixed(1)} km'),
                              ],
                            ),
                          if (distance != null &&
                              userData['location']?['zipCode'] != null)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('•',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          if (userData['location']?['zipCode'] != null)
                            Row(
                              children: [
                                Icon(Icons.map, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(userData['location']['zipCode']),
                              ],
                            ),
                        ],
                      ),
                    ),

                  // Contact Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.contact_phone, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OtherProfileScreen(userData: userData),
                          ),
                        );
                      },
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

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    return (data['name']?.toString().toLowerCase().contains(_searchQuery) ??
            false) ||
        (data['bloodType']?.toString().toLowerCase().contains(_searchQuery) ??
            false) ||
        (data['location']?['zipCode']?.toString().contains(_searchQuery) ??
            false);
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    // Blood Type Filter
    if (_selectedBloodType != null && data['bloodType'] != _selectedBloodType)
      return false;

    // Gender Filter
    if (_selectedGender != null && data['gender'] != _selectedGender)
      return false;

    // Age Filter
    if (data['age'] != null) {
      int age = int.tryParse(data['age']) ?? 0;
      if (_minAge != null && age < _minAge!) return false;
      if (_maxAge != null && age > _maxAge!) return false;
    }

    // Distance Filter
    if (_currentUserPosition != null && data['location'] != null) {
      double distance = calculateDistance(
        _currentUserPosition!.latitude,
        _currentUserPosition!.longitude,
        data['location']['latitude'],
        data['location']['longitude'],
      );
      if (distance > _maxDistance) return false;
    }

    return true;
  }

  void _showFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Create temporary variables to store new filter values
    String? tempBloodType = _selectedBloodType;
    String? tempGender = _selectedGender;
    double tempMaxDistance = _maxDistance;
    int? tempMinAge = _minAge;
    int? tempMaxAge = _maxAge;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.filter_list, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Filter Donors'),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood Type Filter
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Blood Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: tempBloodType,
                        items: [
                          null,
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'O+',
                          'O-',
                          'AB+',
                          'AB-'
                        ]
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type ?? 'All Blood Types'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => tempBloodType = value),
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            color: colorScheme.primary),
                        isExpanded: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gender Filter
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Gender',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: tempGender,
                        items: [null, 'Male', 'Female', 'Other']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender ?? 'All Genders'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => tempGender = value),
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            color: colorScheme.primary),
                        isExpanded: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Distance Filter
                    if (_currentUserPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Distance Range',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color:
                                          colorScheme.primary.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '${tempMaxDistance.round()} km',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor:
                                  isDark ? Colors.grey[700] : Colors.grey[300],
                              trackHeight: 6.0,
                              thumbColor: colorScheme.secondary,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12.0),
                              overlayColor:
                                  colorScheme.primary.withOpacity(0.2),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 24.0),
                              tickMarkShape: const RoundSliderTickMarkShape(
                                  tickMarkRadius: 2.0),
                              activeTickMarkColor: colorScheme.primary,
                              inactiveTickMarkColor:
                                  isDark ? Colors.grey[600] : Colors.grey[300],
                              valueIndicatorColor: colorScheme.primary,
                              valueIndicatorShape:
                                  const PaddleSliderValueIndicatorShape(),
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            child: Slider(
                              value: tempMaxDistance,
                              min: 10,
                              max: 100,
                              divisions: 9,
                              label: '${tempMaxDistance.round()} km',
                              onChanged: (value) =>
                                  setState(() => tempMaxDistance = value),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 6.0, right: 6.0, bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('10',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600])),
                                Text('55',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600])),
                                Text('100',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Age Filter
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Age Range',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: TextFormField(
                              initialValue: tempMinAge?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Min Age',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => tempMinAge =
                                  value.isEmpty ? null : int.tryParse(value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: TextFormField(
                              initialValue: tempMaxAge?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Max Age',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => tempMaxAge =
                                  value.isEmpty ? null : int.tryParse(value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  // Apply filters
                  this.setState(() {
                    _selectedBloodType = tempBloodType;
                    _selectedGender = tempGender;
                    _maxDistance = tempMaxDistance;
                    _minAge = tempMinAge;
                    _maxAge = tempMaxAge;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          );
        },
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
