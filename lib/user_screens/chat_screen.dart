import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';
import 'package:pulsepoint_v2/widgets/location_message.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String recipientUserId;

  const ChatScreen({
    required this.conversationId,
    required this.recipientUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? recipientData;

  @override
  void initState() {
    super.initState();
    _fetchRecipientData();
  }

  Future<void> _fetchRecipientData() async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(widget.recipientUserId).get();
    if (doc.exists) {
      setState(() => recipientData = doc.data() as Map<String, dynamic>);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Send message to conversation subcollection
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': user.uid,
        'senderName': userData['name'] ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update conversation last message
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': _messageController.text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _shareLocation() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic>? locationData =
          await LocationUtils.shareLocation(context);

      if (locationData == null) return;

      // Send location message to conversation subcollection
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'senderId': user.uid,
        'senderName': userData['name'] ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'location',
      });

      // Update conversation last message
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '📍 Location shared',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sharing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipientData?['name'] ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                return // Continue from where you left off in the build method

                    ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    var messageData = message.data() as Map<String, dynamic>;
                    bool isMe =
                        _auth.currentUser?.uid == messageData['senderId'];

                    return _buildMessageBubble(messageData, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    Timestamp? timestamp = message['timestamp'] as Timestamp?;
    String time = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : 'Sending...'; // Show "Sending..." if timestamp is null

    // Check if this is a location message
    if (message['type'] == 'location') {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: LocationBubble(
          latitude: message['latitude'],
          longitude: message['longitude'],
          isMe: isMe,
        ),
      );
    }

    // Regular text message
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && recipientData != null)
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                recipientData!['name'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && recipientData != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: recipientData!['profileImageUrl'] != null
                      ? NetworkImage(recipientData!['profileImageUrl'])
                      : null,
                  child: recipientData!['profileImageUrl'] == null
                      ? Icon(Icons.person, size: 16)
                      : null,
                ),
              Flexible(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 16 : 4),
                      topRight: Radius.circular(isMe ? 4 : 16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['text'],
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        time, // ✅ Updated to avoid 'toDate()' error
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _auth.currentUser?.photoURL != null
                      ? NetworkImage(_auth.currentUser!.photoURL!)
                      : null,
                  child: _auth.currentUser?.photoURL == null
                      ? Icon(Icons.person, size: 16)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Location button
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.blue),
            onPressed: _shareLocation,
            tooltip: 'Share location',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

// Add this helper method to handle scrolling
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
