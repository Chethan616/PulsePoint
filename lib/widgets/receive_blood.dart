import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulsepoint_v2/user_screens/other_profiles.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';

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
      child: ListTile(
        title: Text(userData['name'] ?? 'Anonymous'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blood Type: ${userData['bloodType'] ?? 'Unknown'}'),
            if (userData['age'] != null) Text('Age: ${userData['age']}'),
            if (userData['gender'] != null)
              Text('Gender: ${userData['gender']}'),
            if (distance != null)
              Text('Distance: ${distance.toStringAsFixed(1)} km'),
            if (userData['location']?['zipCode'] != null)
              Text('Zip Code: ${userData['location']['zipCode']}'),
          ],
        ),
        trailing: Icon(Icons.contact_phone),
        onTap: () {
          // Navigate to OtherProfileScreen with the user data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherProfileScreen(userData: userData),
            ),
          );
        },
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Donors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: [null, 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type ?? 'All Blood Types'),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedBloodType = value),
                decoration: InputDecoration(labelText: 'Blood Type'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: [null, 'Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender ?? 'All Genders'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              if (_currentUserPosition != null)
                Column(
                  children: [
                    Text('Maximum Distance (km): ${_maxDistance.round()}'),
                    Slider(
                      value: _maxDistance,
                      min: 10,
                      max: 100,
                      divisions: 9,
                      onChanged: (value) =>
                          setState(() => _maxDistance = value),
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Min Age'),
                      onChanged: (value) => _minAge = int.tryParse(value),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Max Age'),
                      onChanged: (value) => _maxAge = int.tryParse(value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
