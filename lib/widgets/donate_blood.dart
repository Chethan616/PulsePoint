import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulsepoint_v2/user_screens/chat_screen.dart';
import 'package:pulsepoint_v2/user_screens/other_profiles.dart';

class DonateBloodScreen extends StatefulWidget {
  @override
  _DonateBloodScreenState createState() => _DonateBloodScreenState();
}

class _DonateBloodScreenState extends State<DonateBloodScreen> {
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
              accuracy: 0.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
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
        title: Text('Find Blood Recipients'),
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
                  return _matchesSearch(data) && _matchesFilters(data, user.id);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot userDoc = filteredUsers[index];
                    return _buildRecipientCard(userDoc);
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
    final colorScheme = Theme.of(context).colorScheme;
    List<Widget> chips = [];

    if (_selectedBloodType != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.bloodtype, size: 18, color: Colors.red),
        label: Text(
          'Blood: $_selectedBloodType',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red[50],
        side: BorderSide(color: Colors.red[200]!),
        deleteIconColor: Colors.red[700],
        onDeleted: () => setState(() => _selectedBloodType = null),
      ));
    }

    if (_selectedGender != null) {
      chips.add(Chip(
        avatar: Icon(
          _selectedGender == 'Male'
              ? Icons.male
              : _selectedGender == 'Female'
                  ? Icons.female
                  : Icons.people,
          size: 18,
          color: Colors.blue,
        ),
        label: Text(
          'Gender: $_selectedGender',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue[50],
        side: BorderSide(color: Colors.blue[200]!),
        deleteIconColor: Colors.blue[700],
        onDeleted: () => setState(() => _selectedGender = null),
      ));
    }

    if (_currentUserPosition != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.place, size: 18, color: Colors.green),
        label: Text(
          'Distance: ${_maxDistance.round()} km',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green[50],
        side: BorderSide(color: Colors.green[200]!),
        deleteIconColor: Colors.green[700],
        onDeleted: () => setState(() => _maxDistance = 50),
      ));
    }

    if (_minAge != null || _maxAge != null) {
      chips.add(Chip(
        avatar:
            const Icon(Icons.calendar_today, size: 18, color: Colors.purple),
        label: Text(
          'Age: ${_minAge ?? ''}-${_maxAge ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.purple[50],
        side: BorderSide(color: Colors.purple[200]!),
        deleteIconColor: Colors.purple[700],
        onDeleted: () => setState(() {
          _minAge = null;
          _maxAge = null;
        }),
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: chip,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRecipientCard(QueryDocumentSnapshot userDoc) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String recipientUserId = userDoc.id;

    // Add userId to userData for proper navigation to OtherProfileScreen
    userData = Map<String, dynamic>.from(userData);
    userData['uid'] = recipientUserId;

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OtherProfileScreen(userData: userData),
                  ),
                );
              },
              child: CircleAvatar(
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
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OtherProfileScreen(userData: userData),
                            ),
                          );
                        },
                        child: Text(
                          userData['name'] ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
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
                  if (userData['healthAddictions'] != null &&
                      userData['healthAddictions'].toString().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.healing, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Health Info: ${userData['healthAddictions']}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
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
                        SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
                            User? currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;

                            String conversationId = _generateConversationId(
                                currentUser.uid, recipientUserId);

                            // Check/create conversation document
                            final conversationDoc = await FirebaseFirestore
                                .instance
                                .collection('conversations')
                                .doc(conversationId)
                                .get();

                            if (!conversationDoc.exists) {
                              await FirebaseFirestore.instance
                                  .collection('conversations')
                                  .doc(conversationId)
                                  .set({
                                'participants': [
                                  currentUser.uid,
                                  recipientUserId
                                ],
                                'lastMessage': '',
                                'lastMessageTimestamp':
                                    FieldValue.serverTimestamp(),
                              });
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: conversationId,
                                  recipientUserId: recipientUserId,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  color: Colors.blue[700], size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _generateConversationId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
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

  bool _matchesFilters(Map<String, dynamic> data, String documentId) {
    // Exclude current user from the list
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && currentUserId == documentId) {
      return false;
    }

    if (_selectedBloodType != null && data['bloodType'] != _selectedBloodType)
      return false;
    if (_selectedGender != null && data['gender'] != _selectedGender)
      return false;
    if (data['age'] != null) {
      int age = int.tryParse(data['age']) ?? 0;
      if (_minAge != null && age < _minAge!) return false;
      if (_maxAge != null && age > _maxAge!) return false;
    }
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
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Filter Recipients'),
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
                      onChanged: (value) => setState(() => tempGender = value),
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
                                    color: colorScheme.primary.withOpacity(0.5),
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
                            overlayColor: colorScheme.primary.withOpacity(0.2),
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
                            min: 5,
                            max: 200,
                            divisions: 39, // To get increments of 5
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
                              Text('5',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600])),
                              Text('50',
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
                              Text('150',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600])),
                              Text('200',
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
                            decoration: const InputDecoration(
                              labelText: 'Min Age',
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
                            decoration: const InputDecoration(
                              labelText: 'Max Age',
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
      }),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
