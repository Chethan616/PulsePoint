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
import 'package:intl/intl.dart';
import 'package:pulsepoint/utilities/location_utils.dart';
import 'package:pulsepoint/widgets/location_message.dart';
import 'package:pulsepoint/user_screens/other_profiles.dart';
import 'package:pulsepoint/services/notification_service.dart';
import 'package:pulsepoint/providers/donation_service.dart';

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
    bool isOffer = data['isOffer'] == true;

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
            if (isOffer)
              Chip(
                label: Text('OFFERED HELP'),
                backgroundColor: Colors.green[100],
              ),
            // Add Accept Help button - only show to thread author for offers
            if (isOffer)
              FutureBuilder<List<bool>>(
                future: Future.wait([_isThreadAuthor(), _isThreadClosed()]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox
                        .shrink(); // Don't show anything while loading
                  }

                  bool isAuthor = snapshot.data?[0] ?? false;
                  bool isClosed = snapshot.data?[1] ?? true;

                  if (isAuthor && !isClosed) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptHelpOffer(reply),
                        icon: Icon(Icons.check_circle),
                        label: Text('Accept Help'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink(); // Don't show the button
                  }
                },
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

    try {
      final String authorName = await _getUserName();
      final String authorId = _currentUser?.uid ?? '';

      print(
          'Submitting reply - authorId: $authorId, authorName: $authorName, isOffer: $isOffer');

      // Get the thread details to find the recipient (thread author)
      DocumentSnapshot threadDoc = await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .get();

      String recipientUserId = threadDoc['authorId'];
      String threadTitle = threadDoc['title'];

      print(
          'Thread details - recipientUserId: $recipientUserId, threadTitle: $threadTitle');

      // Add the reply to Firestore
      await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .collection('replies')
          .add({
        'content': isOffer ? 'I can help!' : _replyController.text,
        'authorId': authorId,
        'authorName': authorName,
        'profileImageUrl':
            await _getUserProfileImageUrl(), // Add profile image URL
        'timestamp': DateTime.now(),
        'isOffer': isOffer, // Add the 'isOffer' field
        'type':
            'text', // Add type field to distinguish between text and location
      });

      // Update reply count
      _firestore.collection('blood_requests').doc(widget.threadId).update({
        'replyCount': FieldValue.increment(1),
      });

      // Send notification to the thread author
      if (authorId != recipientUserId) {
        print('Sending notification to: $recipientUserId');
        String notificationTitle = isOffer
            ? 'Someone offered to help!'
            : 'New reply to your blood request';
        String notificationBody = isOffer
            ? '$authorName offered to help with your request for $threadTitle'
            : '$authorName replied: ${_replyController.text}';

        print('Notification title: $notificationTitle');
        print('Notification body: $notificationBody');

        await NotificationService().sendBloodRequestThreadNotification(
          requestId: widget.threadId,
          authorId: authorId,
          authorName: authorName,
          recipientUserId: recipientUserId,
          title: notificationTitle,
          body: notificationBody,
          type: isOffer ? 'offer' : 'reply',
        );

        print('Notification sent successfully');
      } else {
        print('Skipping notification as author and recipient are the same');
      }

      _replyController.clear();
    } catch (e, stackTrace) {
      print('Error in _submitReply: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _shareLocation() async {
    try {
      Map<String, dynamic>? locationData =
          await LocationUtils.shareLocation(context);
      if (locationData == null) {
        print('No location data available');
        return;
      }

      final String authorName = await _getUserName();
      final String authorId = _currentUser?.uid ?? '';

      print('Sharing location - authorId: $authorId, authorName: $authorName');
      print('Location data: $locationData');

      // Get the thread details to find the recipient (thread author)
      DocumentSnapshot threadDoc = await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .get();

      String recipientUserId = threadDoc['authorId'];
      String threadTitle = threadDoc['title'];

      print(
          'Thread details - recipientUserId: $recipientUserId, threadTitle: $threadTitle');

      await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .collection('replies')
          .add({
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'authorId': authorId,
        'authorName': authorName,
        'profileImageUrl': await _getUserProfileImageUrl(),
        'timestamp': DateTime.now(),
        'isOffer': false,
        'type': 'location',
      });

      // Update reply count
      _firestore.collection('blood_requests').doc(widget.threadId).update({
        'replyCount': FieldValue.increment(1),
      });

      // Send notification to the thread author
      if (authorId != recipientUserId) {
        print('Sending location notification to: $recipientUserId');
        String notificationTitle = 'Location shared on your blood request';
        String notificationBody =
            '$authorName shared their location for your request: $threadTitle';

        print('Notification title: $notificationTitle');
        print('Notification body: $notificationBody');

        await NotificationService().sendBloodRequestThreadNotification(
          requestId: widget.threadId,
          authorId: authorId,
          authorName: authorName,
          recipientUserId: recipientUserId,
          title: notificationTitle,
          body: notificationBody,
          type: 'location',
        );

        print('Location notification sent successfully');
      } else {
        print(
            'Skipping location notification as author and recipient are the same');
      }
    } catch (e, stackTrace) {
      print('Error in _shareLocation: $e');
      print('Stack trace: $stackTrace');
    }
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

  // Add helper method to check if current user is thread author
  Future<bool> _isThreadAuthor() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .get();
      return doc['authorId'] == _currentUser?.uid;
    } catch (e) {
      print('Error checking thread author: $e');
      return false;
    }
  }

  // Add helper method to check if thread is closed
  Future<bool> _isThreadClosed() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .get();
      return doc['status'] == 'closed';
    } catch (e) {
      print('Error checking thread status: $e');
      return true; // Assume closed on error
    }
  }

  // Implement accept help functionality
  Future<void> _acceptHelpOffer(DocumentSnapshot reply) async {
    try {
      Map<String, dynamic> data = reply.data() as Map<String, dynamic>;
      String donorId = data['authorId'];
      String donorName = data['authorName'];

      // Get thread data to fill donation request details
      DocumentSnapshot threadDoc = await _firestore
          .collection('blood_requests')
          .doc(widget.threadId)
          .get();

      Map<String, dynamic> threadData =
          threadDoc.data() as Map<String, dynamic>;
      String recipientName = threadData['authorName'];
      String bloodType = threadData['bloodType'] ?? 'Unknown';

      // Create donation record
      final donationService = DonationService();
      String? donationId = await donationService.createDonationRequest(
        donorId: donorId,
        donorName: donorName,
        recipientName: recipientName,
        donorPhone: 'Unknown', // These would be populated in a real app
        recipientPhone: 'Unknown',
        bloodType: bloodType,
        location: 'From blood request thread',
        hospitalName: 'To be determined',
        notes: 'Accepted from blood request thread: ${threadData['title']}',
        additionalData: {
          'threadId': widget.threadId,
          'offerId': reply.id,
        },
      );

      if (donationId != null) {
        // Mark the thread as closed since help was accepted
        await _firestore
            .collection('blood_requests')
            .doc(widget.threadId)
            .update({'status': 'closed'});

        // Add a system message to the thread
        await _firestore
            .collection('blood_requests')
            .doc(widget.threadId)
            .collection('replies')
            .add({
          'content':
              '${recipientName} has accepted help from ${donorName}. This request is now closed.',
          'authorId': 'system',
          'authorName': 'System',
          'timestamp': DateTime.now(),
          'isOffer': false,
          'type': 'text',
          'isSystem': true,
        });

        // Automatically mark the donation as completed for statistics tracking
        await donationService.completeDonation(donationId);

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Help offer accepted! A donation record has been created.')));

        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      print('Error accepting help offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting help offer: $e')));
    }
  }
}
