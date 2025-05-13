import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';
import 'package:pulsepoint_v2/widgets/location_message.dart';

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
                      CircleAvatar(
                        backgroundImage: NetworkImage(data['profileImageUrl'] ??
                            'default_image_url'), // Default image URL
                        radius: 20,
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
                  Text(' ${data['authorName']}  •  '),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Blood Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
          ],
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
                await _firestore.collection('blood_requests').add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'authorId': _currentUser?.uid,
                  'authorName': await _getUserName(),
                  'timestamp': DateTime.now(),
                  'status': 'open',
                  'replyCount': 0, // Initialize the reply count
                  'profileImageUrl':
                      await _getUserProfileImageUrl(), // Add profile image URL
                });

                Navigator.pop(context);
              }
            },
            child: Text('Post'),
          ),
        ],
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
                CircleAvatar(
                  backgroundImage: NetworkImage(data['profileImageUrl'] ??
                      'default_image_url'), // Default image URL
                  radius: 16,
                ),
                SizedBox(width: 8),
                Text(data['authorName'],
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
}
