import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';
import 'package:pulsepoint_v2/widgets/location_message.dart';
import 'package:pulsepoint_v2/user_screens/other_profiles.dart';
import 'package:pulsepoint_v2/services/notification_service.dart';

class BloodPage extends StatefulWidget {
  @override
  _BloodPageState createState() => _BloodPageState();
}

class _BloodPageState extends State<BloodPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => _showHelpInfo(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateThreadDialog(),
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('blood_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var thread = snapshot.data!.docs[index];
              return _buildThreadCard(thread);
            },
          );
        },
      ),
    );
  }

  Widget _buildThreadCard(DocumentSnapshot thread) {
    Map<String, dynamic> data = thread.data() as Map<String, dynamic>;
    bool isClosed = data['status'] == 'closed';
    bool isAuthor = _currentUser?.uid == data['authorId'];

    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _navigateToThreadDetail(thread.id),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(data['authorId'],
                            data['authorName'], data['profileImageUrl']),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                              data['profileImageUrl'] ??
                                  'default_image_url'), // Default image URL
                          radius: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        data['title'],
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(isClosed ? 'CLOSED' : 'OPEN'),
                    backgroundColor: isClosed ? Colors.grey : Colors.green,
                  )
                ],
              ),
              SizedBox(height: 8),
              Text(data['content']),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16),
                  GestureDetector(
                    onTap: () => _navigateToUserProfile(data['authorId'],
                        data['authorName'], data['profileImageUrl']),
                    child: Text(
                      ' ${data['authorName']}  •  ',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.access_time, size: 16),
                  Text(
                      ' ${DateFormat('MMM dd, HH:mm').format(data['timestamp'].toDate())}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateThreadDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();
    String selectedBloodType = 'Any';

    // Get options for blood type dropdown
    final bloodTypes = [
      'Any',
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('New Blood Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(labelText: 'Details'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Blood Type Needed:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBloodType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: bloodTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedBloodType = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  // Start with location fetch to avoid delays later
                  Map<String, dynamic>? locationData =
                      await LocationUtils.getUserLocation();
                  double? latitude, longitude;

                  // Extract location data
                  if (locationData != null) {
                    latitude = locationData['latitude'];
                    longitude = locationData['longitude'];
                  }

                  // Get user data
                  String userName = await _getUserName();
                  String profileImageUrl = await _getUserProfileImageUrl();

                  // Create the blood request
                  DocumentReference docRef =
                      await _firestore.collection('blood_requests').add({
                    'title': titleController.text,
                    'content': contentController.text,
                    'bloodType': selectedBloodType,
                    'authorId': _currentUser?.uid,
                    'authorName': userName,
                    'timestamp': DateTime.now(),
                    'status': 'open',
                    'replyCount': 0,
                    'profileImageUrl': profileImageUrl,
                    'location': locationData,
                  });

                  Navigator.pop(context);

                  // Send notifications to nearby users if location is available
                  if (latitude != null && longitude != null) {
                    await NotificationService().sendBloodRequestNotifications(
                      bloodType: selectedBloodType,
                      latitude: latitude,
                      longitude: longitude,
                      requestId: docRef.id,
                      title: 'Urgent Blood Request Nearby',
                      body:
                          '${userName} needs ${selectedBloodType} blood: ${titleController.text}',
                    );
                  }
                }
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getUserName() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_currentUser?.uid).get();
    return userDoc['name'] ?? 'Anonymous';
  }

  Future<String> _getUserProfileImageUrl() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_currentUser?.uid).get();
    return userDoc['profileImageUrl'] ??
        'default_image_url'; // Default profile image URL
  }

  void _navigateToThreadDetail(String threadId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreadDetailPage(threadId: threadId),
      ),
    );
  }

  void _showHelpInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How it works'),
        content: Text(
            'Post your blood requirement here. Other users can offer help. '
            'Mark requests as closed when resolved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method to navigate to user profile
  void _navigateToUserProfile(
      String userId, String userName, String? profileImageUrl) async {
    if (userId.isEmpty) return;

    // Check if this is the current user's profile
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      // Navigate to the main profile screen instead
      Navigator.pushNamed(context, '/profile');
      return;
    }

    try {
      // Fetch complete user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Ensure uid field is set
        userData['uid'] = userId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileScreen(userData: userData),
          ),
        );
      } else {
        // Fallback if user doc doesn't exist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileScreen(userData: {
              'uid': userId,
              'name': userName,
              'profileImageUrl': profileImageUrl,
            }),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to user profile: $e');
      // Fallback with minimal data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfileScreen(userData: {
            'uid': userId,
            'name': userName,
            'profileImageUrl': profileImageUrl,
          }),
        ),
      );
    }
  }
}

class ThreadDetailPage extends StatefulWidget {
  final String threadId;

  ThreadDetailPage({required this.threadId});

  @override
  _ThreadDetailPageState createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('blood_requests')
            .doc(widget.threadId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var thread = snapshot.data!;
          bool isClosed = thread['status'] == 'closed';
          bool isAuthor = _currentUser?.uid == thread['authorId'];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread['title'],
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(thread['content']),
                      SizedBox(height: 16),
                      Text(
                        'Replies (${thread['replyCount'] ?? 0})',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('blood_requests')
                            .doc(widget.threadId)
                            .collection('replies')
                            .orderBy('timestamp')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var reply = snapshot.data!.docs[index];
                              return _buildReplyCard(reply);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (!isClosed && !isAuthor) _buildOfferHelpButton(),
              if (isAuthor) _buildThreadControls(thread),
              _buildReplyInput(isClosed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReplyCard(DocumentSnapshot reply) {
    Map<String, dynamic> data = reply.data() as Map<String, dynamic>;

    // Check if this is a location message
    if (data['type'] == 'location') {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: LocationMessage(
          latitude: data['latitude'],
          longitude: data['longitude'],
          senderName: data['authorName'],
          timestamp: data['timestamp'].toDate(),
        ),
      );
    }

    // Regular text reply
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserProfile(data['authorId'],
                      data['authorName'], data['profileImageUrl']),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(data['profileImageUrl'] ??
                        'default_image_url'), // Default image URL
                    radius: 16,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _navigateToUserProfile(data['authorId'],
                      data['authorName'], data['profileImageUrl']),
                  child: Text(
                    data['authorName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(DateFormat('MMM dd, HH:mm')
                    .format(data['timestamp'].toDate())),
              ],
            ),
            SizedBox(height: 4),
            Text(data['content']),
            if (data['isOffer'] == true)
              Chip(
                label: Text('OFFERED HELP'),
                backgroundColor: Colors.green[100],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferHelpButton() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: ElevatedButton.icon(
        icon: Icon(Icons.volunteer_activism),
        label: Text('Offer Help'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: () => _submitReply(isOffer: true),
      ),
    );
  }

  Widget _buildThreadControls(DocumentSnapshot thread) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () => _toggleThreadStatus(thread),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  thread['status'] == 'open' ? Colors.red : Colors.green,
            ),
            child: Text(thread['status'] == 'open'
                ? 'Close Request'
                : 'Reopen Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(bool isClosed) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          // Location button
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.blue),
            onPressed: isClosed ? null : _shareLocation,
            tooltip: 'Share location',
          ),
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText:
                    isClosed ? 'This thread is closed' : 'Add a comment...',
                enabled: !isClosed,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: isClosed ? null : () => _submitReply(),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply({bool isOffer = false}) async {
    if (_replyController.text.isEmpty && !isOffer) return;

    await _firestore
        .collection('blood_requests')
        .doc(widget.threadId)
        .collection('replies')
        .add({
      'content': isOffer ? 'I can help!' : _replyController.text,
      'authorId': _currentUser?.uid,
      'authorName': await _getUserName(),
      'profileImageUrl':
          await _getUserProfileImageUrl(), // Add profile image URL
      'timestamp': DateTime.now(),
      'isOffer': isOffer, // Add the 'isOffer' field
      'type': 'text', // Add type field to distinguish between text and location
    });

    // Update reply count
    _firestore.collection('blood_requests').doc(widget.threadId).update({
      'replyCount': FieldValue.increment(1),
    });

    _replyController.clear();
  }

  Future<void> _shareLocation() async {
    Map<String, dynamic>? locationData =
        await LocationUtils.shareLocation(context);
    if (locationData == null) return;

    await _firestore
        .collection('blood_requests')
        .doc(widget.threadId)
        .collection('replies')
        .add({
      'latitude': locationData['latitude'],
      'longitude': locationData['longitude'],
      'authorId': _currentUser?.uid,
      'authorName': await _getUserName(),
      'profileImageUrl': await _getUserProfileImageUrl(),
      'timestamp': DateTime.now(),
      'isOffer': false,
      'type': 'location',
    });

    // Update reply count
    _firestore.collection('blood_requests').doc(widget.threadId).update({
      'replyCount': FieldValue.increment(1),
    });
  }

  Future<void> _toggleThreadStatus(DocumentSnapshot thread) async {
    String newStatus = thread['status'] == 'open' ? 'closed' : 'open';
    await _firestore
        .collection('blood_requests')
        .doc(widget.threadId)
        .update({'status': newStatus});

    setState(() {}); // Force UI to rebuild and show updated status
  }

  Future<String> _getUserName() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_currentUser?.uid).get();
    return userDoc['name'] ?? 'Anonymous';
  }

  Future<String> _getUserProfileImageUrl() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_currentUser?.uid).get();
    return userDoc['profileImageUrl'] ??
        'default_image_url'; // Default profile image URL
  }

  // Navigate to user profile
  void _navigateToUserProfile(
      String userId, String userName, String? profileImageUrl) async {
    if (userId.isEmpty) return;

    // Check if this is the current user's profile
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      // Navigate to the main profile screen instead
      Navigator.pushNamed(context, '/profile');
      return;
    }

    try {
      // Fetch complete user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Ensure uid field is set
        userData['uid'] = userId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileScreen(userData: userData),
          ),
        );
      } else {
        // Fallback if user doc doesn't exist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileScreen(userData: {
              'uid': userId,
              'name': userName,
              'profileImageUrl': profileImageUrl,
            }),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to user profile: $e');
      // Fallback with minimal data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfileScreen(userData: {
            'uid': userId,
            'name': userName,
            'profileImageUrl': profileImageUrl,
          }),
        ),
      );
    }
  }
}
